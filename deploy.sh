#!/bin/bash

rm -rf public

hugo

rsync \
	--chown=www-data:www-data \
	--rsync-path="sudo rsync" \
	-Pr \
	--chmod="D755,F644" \
	--delete \
	-c \
	public/ server:/var/www/html/mariomoura.com/
