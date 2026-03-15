# Amikiyo — Anime Social Platform

A full-stack mobile social media platform built for anime communities.

Amikiyo combines the core interaction model of modern social media platforms with anime-focused features, allowing users to share content, track anime, communicate with friends, and participate in communities.

The system consists of a **Flutter cross-platform mobile application** powered by a **Django REST backend API**, with real-time messaging supported through Firebase services.

---

# Tech Stack

## Mobile Application

* Flutter
* Dart
* Firebase Authentication
* Firebase Messaging
* REST API Integration

## Backend System

* Python
* Django
* Django REST Framework
* JWT Authentication
* Docker containerization
* Cloud-ready backend architecture

## Infrastructure

* Firebase (Realtime messaging and notifications)
* Media storage system
* Containerized backend deployment

---

# Core Platform Features

## User Accounts & Profiles

* User registration and authentication
* Profile creation and editing
* Profile picture management
* Public user profiles
* User search functionality
* Follow / unfollow users
* Followers and following lists

---

# Social Media Features

The platform replicates key interaction patterns found in modern social networks.

### Posts System

* Create image posts
* Caption support
* Post feed system
* View individual post details
* Delete posts
* Post engagement tracking
* Like / unlike posts

### Comments System

* Add comments to posts
* Fetch post comments
* Delete comments

### Personalized Home Feed

* Dynamic feed generated from followed users
* Optimized API responses for mobile clients

---

# Story System (Similar to Instagram)

Users can share temporary content visible for a limited duration.

Features include:

* Create stories
* View story feed
* Track story viewers
* View individual stories
* Delete stories
* View personal story archive

---

# Messaging System

Real-time messaging infrastructure integrated with Firebase.

Features include:

* One-to-one chat rooms
* Chat room creation or retrieval
* Chat room listing
* Message exchange through real-time services

---

# Groups / Community System

Users can create private communities and interact with other members.

Features include:

* Create groups
* Request to join groups
* Approve or reject join requests
* Add members
* Remove members
* Leave group
* Transfer group ownership
* Update group details
* Group search functionality

---

# Anime Board System

A dedicated anime tracking feature built specifically for anime fans.

Users can manage their anime preferences through categorized lists:

### Anime Lists

* Favorite Anime
* Watched Anime
* Next to Watch

This allows users to maintain a personal anime board similar to anime tracking platforms while keeping the experience integrated within the social network.

---

# Media System

The platform supports media uploads and storage.

Features include:

* Image upload for posts
* Story media support
* Profile image management
* Media file storage system

---

# API Architecture

The backend exposes RESTful APIs consumed by the Flutter mobile application.

Example endpoints:

```
/users/
/posts/
/profiles/search/
/home-feed/
/chat/get-or-create/
/groups/create/
/story/create/
```

The API architecture follows modular separation between:

* models
* serializers
* views
* routing

This structure ensures maintainability and scalability.

---

# Repository Structure

```
lib/
 ├── src/
 ├── assets/
 ├── main.dart
 └── firebase_options.dart

android/
ios/
web/
windows/
linux/
macos/
```

---

# Project Vision

Amikiyo aims to combine **anime culture with modern social interaction**, enabling fans to:

* share anime content
* connect with other fans
* track anime preferences
* participate in communities
* communicate through messaging

The architecture is designed to scale as a full social networking platform.

---

# Author

Ayush Rawat
Full-Stack Developer (Flutter + Django)
