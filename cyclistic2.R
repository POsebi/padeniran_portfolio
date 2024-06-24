# collecting data and creating dataframe

library(data.table)
setwd("C:\\Users\\Princess\\Documents\\Portfolio\\Case Study 1\\divvy_dataset")
files <- list.files(pattern = ".csv")
temp <- lapply(files, fread, sep = ",")
cyclistic_dataset <- rbindlist(temp)

#overview of data

head(cyclistic_dataset)
glimpse(cyclistic_dataset)
colnames(cyclistic_dataset)

# to wrangle data

library(tidyverse)

# to manage conflicts
library(conflicted)

# setting conflict preferences for packages
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_prefer("month", "lubridate")
conflict_prefer("year", "lubridate")
conflict_prefer("day", "lubridate")
conflict_prefer("wday", "lubridate")

# inspecting dataframe to check for inconsistencies

str(cyclistic_dataset)

# removing unneeded columns

all_trips <- cyclistic_dataset %>%
  select(-c(start_lat, start_lng, end_lat, end_lng))

#inspecting new dataframe for possible errors

colnames(all_trips)
tail(all_trips)
dim(all_trips)
summary(all_trips)

all_trips %>%
  distinct(member_casual)
all_trips %>%
  distinct(rideable_type)
all_trips %>%
  distinct(start_station_name)
all_trips %>%
  distinct(end_station_name)

# extracting and formatting date, day, month, and year columns of each ride to enable improved aggregation

all_trips$date <- as.Date(all_trips$started_at)
all_trips$month <- format(as.Date(all_trips$date), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%a")

#adding column for length of ride

all_trips$ride_length <- difftime(all_trips$ended_at,all_trips$started_at)

#checking accuracy and structure of newly added columns

str(all_trips)
colnames(all_trips)

# The dataframe includes a few hundred entries when bikes were taken out of docks and checked for quality by Divvy or ride_length was negative
# removing "bad" data and creating new version of dataframe

all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | all_trips$ride_length<0),]

#conduting descriptive analysis

summary(all_trips_v2$ride_length)
#straight average (total ride length / rides)
mean(all_trips_v2$ride_length) 
#midpoint number in the ascending array of ride lengths
median(all_trips_v2$ride_length) 
#longest ride
max(all_trips_v2$ride_length)
#shortest ride
min(all_trips_v2$ride_length)

# comparing members and casual users

aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)

# checking average ride time by each day for members vs casual users

aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week,
          FUN = mean)

# re-ordering day_of_week

all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, levels=c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"))

# running average ride time by each day for members vs casual users after re-ordering
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week,
          FUN = mean)

# analyze ridership data by type and weekday
all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n(), average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday)

# visualizing the number of rides by rider type by year

all_trips_v2 %>%
  group_by(member_casual, year) %>%
  summarise(number_of_rides = n(),average_duration = mean(ride_length)) %>%
  arrange(member_casual, year) %>%
  ggplot(aes(x = year, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

# visualizing number of rides by rider type by weekday

all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n(),average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday) %>%
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

# visualizing for average duration ride type by year

all_trips_v2 %>%
  group_by(member_casual, year) %>%
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%
  arrange(member_casual, year) %>%
  ggplot(aes(x = year, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

# visualizing for average duration by ride type by weekday

all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday) %>%
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

# creating csv file to visualize in Tableau

  counts <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual +
                        all_trips_v2$day_of_week + all_trips_v2$month + all_trips_v2$year, FUN = mean)
  write.csv(counts, file = 'avg_ride_length.csv')
  