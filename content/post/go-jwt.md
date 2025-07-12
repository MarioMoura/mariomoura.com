---
title: "Making a simple JWT middleware for go-gin"
date: 2025-07-12T16:17:21-03:00
tags:
  - jwt
  - go
  - security
image: '/img/posts/go-jwt.jpg'
comments: true
summary:  'How to use "golang-jwt" module to issue and verify tokens.'
params:
    dotfile: false
---


# Why?

[Go-gin](https://github.com/gin-gonic/gin) is my framework of choice when writing
the backend in GO, naturally I need some way of authentication my users. In short:
I wanted to learn how JWT really works by (kinda) implementing it myself.

# JWT

I'm not going to bother explaining what JWT is, it is a token format,
there's a lot of good information about it, you can find more about it here:
- https://jwt.io/introduction
- https://en.wikipedia.org/wiki/JSON_Web_Token
- https://datatracker.ietf.org/doc/html/rfc7519

# Scope

What are we doing today? Issuing and verifying tokens. Are we writing the libraries that
generate the tokens? No.

The steps are as follows:
- Generate a private key
- Issue tokens for a given user
- Verify a token

Also, this is made to be used with go-gin, but the logic can be used elsewhere, anywhere really.

# Generating the key

```bash
openssl genrsa -out <file> 4096
```

In this example I'm using `server.priv` as the filename.

Now we need to read the file in go:

```go
package main

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"log"
	"os"
    "fmt"
)

// global private key
var key *rsa.PrivateKey
// global public key
var key_pub *rsa.PublicKey
// change this to your key path
var private_key_path string = "server.priv"

func InitKey() {
    // Get file contents, gennarally in the PEM format
	key_raw, err := os.ReadFile(private_key_path)
	if err != nil {
		log.Fatal("Error opening file:", err)
	}
    // Decode PEM
	pem, _ := pem.Decode(key_raw)
	if pem == nil || pem.Type != "RSA PRIVATE KEY" && pem.Type != "PRIVATE KEY" {
		log.Fatal("Failed to decode PEM block or block is not an RSA private key")
	}
	pkcs8Key, err := x509.ParsePKCS8PrivateKey(pem.Bytes)
	if err != nil {
		log.Fatal("Error parsing key:", err)
	}
	key = pkcs8Key.(*rsa.PrivateKey)
	key_pub = key.Public().(*rsa.PublicKey)
}
```

Now let's add a small test:
```go
func main() {
	InitKey()
	fmt.Println(key)
}
```
It's going to be a lot of text, but if you see something it means it worked.

# Issuing the token

To issue the token:
```go
type LocalClaims struct {
	UserEmail string `json:"useremail"`
	UserId    string `json:"userid"`
	jwt.RegisteredClaims
}

func GenerateToken(user string, userid string) string {
	claims := LocalClaims{
		user,
		userid,
		jwt.RegisteredClaims{
			Issuer:    "us >:D",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(0 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Subject:   "test",
			ID:        userid,
			Audience:  []string{"test"},
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS512, claims)
	signed_token, err := token.SignedString(key)
	if err != nil {
		log.Fatal("Error signing the token: ", err)
	}
	return signed_token
}
```

Make sure you add to imports:
```go
	"github.com/golang-jwt/jwt/v5"
	"time"
```

Now let's test it:
```go
func main() {
	InitKey()
	//fmt.Println(key)
	token := GenerateToken("myself", "1234")
	fmt.Println(token)

}
```

Now if you run something like this: `go run .`, you will get your token as the output.
And we can parse it like this:

First field:
```bash
go run . | cut -d '.' -f 1 | base64 -d
```
Output:
```
{
  "alg": "RS512",
  "typ": "JWT"
}
```

Second Field:
```bash
go run . | cut -d '.' -f 2 | base64 -d
```
Output:
```
{
  "useremail": "myself",
  "userid": "1234",
  "iss": "us >:D",
  "sub": "test",
  "aud": [
    "test"
  ],
  "exp": 1752351417,
  "nbf": 1752351417,
  "iat": 1752351417,
  "jti": "1234"
}
```

You can add the claims you want by editing the `LocalClaims` struct.

# Verifying the token

The JWT library provides us a parser that already verifies the token for us:
```go
func VerifyToken(tokenString string) bool {
	token, err := jwt.ParseWithClaims(tokenString, &LocalClaims{}, func(token *jwt.Token) (any, error) {
		return key_pub, nil
	})
	if err != nil {
		fmt.Println(err)
		return false
	}
	if token.Valid == false {
		fmt.Println("Token not valid")
		return false
	}
	return token.Valid
}
```
We are not going to use this function when building the middleware, this is a illustration on how
`ParseWithClaims` works.

Testing:
```go
func main() {
	InitKey()
	token := GenerateToken("myself", "1234")
	fmt.Println(VerifyToken(token))
}
```
The output should be a simple `true`. But if you change the expiration for the token like this:
```go
ExpiresAt: jwt.NewNumericDate(time.Now().Add(0 * time.Hour)),
```
Meaning the token will be automatically expired after its generation. Then you will get:
```
token has invalid claims: token is expired
false
```

For the sake of learning (or curiosity), you can play around with those functions, hard-coding a token
a modifying it to see what happens is fun.

# The Middleware

As I state previously I'm not using the `VerifyToken` function in the end product, though it's going to be
quite similar.

Here's the middleware:
```go
func JwtMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := c.GetHeader("Authorization")
		if tokenString == "" {
			c.JSON(401, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		token, err := jwt.ParseWithClaims(tokenString, &LocalClaims{}, func(token *jwt.Token) (any, error) {
			return key_pub, nil
		})
		if err != nil {
			fmt.Println(err)
			c.JSON(401, gin.H{"error": "Error decoding token"})
			c.Abort()
			return
		}
		if token.Valid == false {
			fmt.Println(err)
			c.JSON(401, gin.H{"error": "Token not Valid"})
			c.Abort()
			return
		}
		c.Next()
	}
}
```
Don't forget to add the import: `"github.com/gin-gonic/gin"`.

This will essentially do what the `VerifyToken` function did, but in a gin context.
Now we can use it in gin like this:
```go
protected := r.Group("/locked")
protected.Use(JwtMiddleware())
protected.GET("/<path>", ... )
```

# Full example

```go
package main

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"log"
	"os"
	"time"
)

// global private key
var key *rsa.PrivateKey

// global public key
var key_pub *rsa.PublicKey

// change this to your key path
var private_key_path string = "server.priv"

func InitKey() {
	// Get file contents, gennarally in the PEM format
	key_raw, err := os.ReadFile(private_key_path)
	if err != nil {
		log.Fatal("Error opening file:", err)
	}
	// Decode PEM
	pem, _ := pem.Decode(key_raw)
	if pem == nil || pem.Type != "RSA PRIVATE KEY" && pem.Type != "PRIVATE KEY" {
		log.Fatal("Failed to decode PEM block or block is not an RSA private key")
	}
	pkcs8Key, err := x509.ParsePKCS8PrivateKey(pem.Bytes)
	if err != nil {
		log.Fatal("Error parsing key:", err)
	}
	key = pkcs8Key.(*rsa.PrivateKey)
	key_pub = key.Public().(*rsa.PublicKey)
}

type LocalClaims struct {
	UserEmail string `json:"useremail"`
	UserId    string `json:"userid"`
	jwt.RegisteredClaims
}

func GenerateToken(user string, userid string) string {
	claims := LocalClaims{
		user,
		userid,
		jwt.RegisteredClaims{
			Issuer:    "us >:D",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(0 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Subject:   "test",
			ID:        userid,
			Audience:  []string{"test"},
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS512, claims)
	signed_token, err := token.SignedString(key)
	if err != nil {
		log.Fatal("Error signing the token: ", err)
	}
	return signed_token
}

func VerifyToken(tokenString string) bool {
	token, err := jwt.ParseWithClaims(tokenString, &LocalClaims{}, func(token *jwt.Token) (any, error) {
		return key_pub, nil
	})
	if err != nil {
		fmt.Println(err)
		return false
	}
	if token.Valid == false {
		fmt.Println("Token not valid")
		return false
	}
	return token.Valid
}

func JwtMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := c.GetHeader("Authorization")

		if tokenString == "" {
			c.JSON(401, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		token, err := jwt.ParseWithClaims(tokenString, &LocalClaims{}, func(token *jwt.Token) (any, error) {
			return key_pub, nil
		})
		if err != nil {
			fmt.Println(err)
			c.JSON(401, gin.H{"error": "Error decoding token"})
			c.Abort()
			return
		}
		if token.Valid == false {
			fmt.Println(err)
			c.JSON(401, gin.H{"error": "Token not Valid"})
			c.Abort()
			return
		}
		claims := token.Claims.(*LocalClaims)
		c.Set("UserEmail", claims.UserEmail)
		c.Next()
	}
}

func main() {
	InitKey()
	//fmt.Println(key)
	token := GenerateToken("myself", "1234")

	fmt.Println(VerifyToken(token))
}
```
