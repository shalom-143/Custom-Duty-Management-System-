# Inspection Module - Customs Duty Management System

## Description
This module handles all Inspection-related operations for the Customs Duty Management System.

## Features
- Complete CRUD operations for Inspection entity
- Secure with JWT authentication
- Optimized PostgreSQL table with proper indexing
- Input validation and error handling
- Pagination support
- Soft delete for audit compliance

## Setup Instructions
1. Copy `.env.example` to `.env` and configure your database
2. Run `npm install`
3. Run `npm run generate`
4. Run `npm run migrate`
5. Run `npm run dev`

## API Endpoints
- **POST** `/api/inspections` - Create new inspection
- **GET** `/api/inspections` - Get all inspections (with filters & pagination)
- **GET** `/api/inspections/:id` - Get single inspection
- **PUT** `/api/inspections/:id` - Update inspection
- **DELETE** `/api/inspections/:id` - Soft delete inspection

## Tech Stack
- Node.js + Express
- Prisma ORM
- PostgreSQL