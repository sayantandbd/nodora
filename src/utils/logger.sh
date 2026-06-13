#!/bin/bash

log_header() {
  local title=$1
  echo "========================================="
  echo "  Nodora: $title  "
  echo "========================================="
}

log_info() {
  echo "$1"
}

log_error() {
  echo "ERROR: $1" >&2
}
