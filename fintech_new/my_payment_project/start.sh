#!/usr/bin/env bash
set -o errexit

gunicorn core.wsgi:application
