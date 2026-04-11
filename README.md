# TourXport

An AI tour generation Flutter app that plans everything you need to know for your tour of choice.

# Requirement

1. Docker
2. Flutter
3. `.env` file (look at `.env.example` file for more info)

# **Build & Debug**

## Backend

Docker compose only backend server (at project root folder)

* Windows

  ```
  docker compose up backend --build
  ```
* Linux

  ```
  docker-compose up backend --build
  ```

## AI Server

Docker compose only backend server (at project root folder)

* Windows

  ```
  docker compose up ai_backend --build
  ```
* Linux

  ```
  docker-compose up ai_backend --build
  ```

## Crawl Server


## Application

Build & run Flutter app (at frontend folder)

  ```
  flutter run -d <YOUR_DEVICE_NAME>
  ```

or if you want to specify custom backend server:

  ```

  ```

