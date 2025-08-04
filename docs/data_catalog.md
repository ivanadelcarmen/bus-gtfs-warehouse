# Data catalog for the gold layer of `gtfswarehouse`

## Overview

The purpose of this gold layer is to provide accurate metrics regarding routes (branches of buses) and bus agencies to analyze relationships between variables, group statistics according to the user's needs, and provide a clear, clean, and normalized EDW to facilitate querying and visualization tasks.

The schema, namely a galaxy schema, is composed by two fact tables with average statistics related to routes and three dimensions which include descriptive data about route shape coordinates, routes, and bus agencies.

## Metadata

### gold.dim_agencies

Provides agency details such as names and URLs.

| Column Name      | Data Type     | Description                                                                    |
|------------------|---------------|--------------------------------------------------------------------------------|
| agency_key       | INT           | Surrogate key uniquely identifying each agency in a stepwise and clear manner. |
| agency_id        | INT           | Unique numerical identifier assigned originally to each agency.                |
| agency_name      | NVARCHAR(100) | Alphabetic identifier representing the agency, used for referencing.           |
| agency_url       | NVARCHAR(100) | The URL provided to find further information on the agency.                    |
| timezone_country | NVARCHAR(30)  | The country related to the agency's timezone.                                  |
| timezone_city    | NVARCHAR(30)  | The city from the country related to the agency's timezone.                        

#

### gold.dim_routes

Provides route properties, descriptions, and bus details.

| Column Name       | Data Type    | Description                                                                                                                |
|-------------------|--------------|----------------------------------------------------------------------------------------------------------------------------|
| route_key         | INT          | Surrogate key uniquely identifying each route in a stepwise and clear manner.                                              |
| route_id          | INT          | Unique numerical identifier assigned originally to each route.                                                             |
| agency_id         | INT          | Numerical identifier of each route's agency. It is considered as a prime property of routes.                               |
| bus_line          | NVARCHAR(5)  | Numerical string name of the bus line to which a route belongs. Only 6 unique values are alphabetic.                       |
| bus_branch        | NVARCHAR(5)  | Alphanumerical category related to the specific route of a bus line.                                                       |
| route_description | TEXT         | A brief description of a route's branch, terminals, or endpoint locations.                                                 |
| route_scope       | NVARCHAR(20) | The region scope of each route with 'Capital' being Buenos Aires capital city, 'Province' being Buenos Aires Province, and 'Municipality' being a single municipality within Buenos Aires Province.

#

### gold.dim_markers

Provides ordered coordinates to visualize the path of routes given an ambivalent direction. 

| Column Name     | Data Type | Description                                                                                                         |
|-----------------|-----------|---------------------------------------------------------------------------------------------------------------------|
| marker_key      | INT       | Artificial numerical and unique identifier for each marker given a route, a direction, an ordinal, and coordinates. |
| route_key       | INT       | Foreign and surrogate key uniquely identifying each route at **gold.dim_routes**.                                   |
| route_direction | INT       | Binary value, oscilating between 0 and 1, to represent the direction of the route's shape.                          |
| marker_ordinal  | INT       | Numerical value to indicate the order by which coordinates grouped by route and direction should be drawn.          |
| marker_lat      | FLOAT     | The shape marker latitude.                                                                                          |
| marker_lon      | FLOAT     | The shape marker longitude.

#

### gold.fact_services

Provides simple metric information on the amount of trips or vehicles per day belonging to a route, given both directions and a specific service type.

| Column Name   | Data Type    | Description                                                                                                |
|---------------|--------------|------------------------------------------------------------------------------------------------------------|
| route_key     | INT          | Foreign and surrogate key uniquely identifying each route at **gold.dim_routes**.                          |
| agency_key    | INT          | Foreign and surrogate key uniquely identifying each agency at **gold.dim_agencies**.                       |
| service_type  | NVARCHAR(20) | The type of service referenced, among: 'Saturday' (including vespers), 'Sunday', 'Weekday', and 'Holiday'. |
| service_trips | INT          | The amount of total trips per day belonging to a route within a service type.

#

### gold.fact_performance

Provides relevant metric information on routes such as number of stops, average distance, average completion time, and total trips per day.

| Column Name        | Data Type | Description                                                                                                     |
|--------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| route_key          | INT       | Foreign and surrogate key uniquely identifying each route at **gold.dim_routes**.                               |
| agency_key         | INT       | Foreign and surrogate key uniquely identifying each agency at **gold.dim_agencies**.                            |
| route_trips        | INT       | The total trips per day belonging to a route, congruent with the sum of all service trips per route.            |
| route_avg_distance | INT       | The mean distance, in meters, completed by a given route considering both directions.                           |
| route_avg_stops    | INT       | The mean number of stops related to a given route considering both directions.                                  |
| route_avg_time     | INT       | The mean time, in minutes, for a given route to be completed considering both directions and each service type. |