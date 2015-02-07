#!/bin/bash

_log () { echo "$*" >&2; }
DEBUG() { _log DEBUG "$@"; }
INFO() { _log INFO "$@"; }
WARN() { _log WARN "$@"; }
ERROR() { _log ERROR "$@"; }
DIE() { _log FATAL "$@"; exit 1; }
