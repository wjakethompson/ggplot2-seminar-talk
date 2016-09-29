library(dplyr)
library(purrr)
library(stringr)

beer_advocate <- read.csv("beeradvocate.com API 26th Sep 14_06.csv", stringsAsFactors = FALSE)

remove_1 <- grep("Results: ", beer_advocate$content_2, fixed = TRUE)
remove_2 <- grep("prev |", beer_advocate$content_2, fixed = TRUE)
remove_3 <- which(beer_advocate$content_2 == "Location")


remove <- c(remove_1, remove_2, remove_3)
beer_advocate <- beer_advocate[-remove,]

row_nums <- seq(1, nrow(beer_advocate), by = 2)

final_list <- list_along(row_nums)
for(i in seq_along(row_nums)) {
  cur_row <- row_nums[i]
  
  cur_brew <- data_frame(brewery_name = beer_advocate[cur_row,"content_2"],
    brewery_rating = beer_advocate[cur_row,"content_3"],
    num_reviews = beer_advocate[cur_row,"content_4"],
    beer_avg = beer_advocate[cur_row,"content_5"],
    num_beers = beer_advocate[cur_row,"content_6"],
    address = beer_advocate[cur_row + 1, "content_2"],
    type = beer_advocate[cur_row + 1, "content_5"],
    city = substr(beer_advocate[cur_row + 1, "links_3._text"], 1,
      gregexpr(";", beer_advocate[cur_row + 1, "links_3._text"])[[1]][1] - 1),
    state = substr(beer_advocate[cur_row + 1, "links_3._text"],
      gregexpr(";", beer_advocate[cur_row + 1, "links_3._text"])[[1]][1] + 2,
      gregexpr(";", beer_advocate[cur_row + 1, "links_3._text"])[[1]][2] - 1))
  
  final_list[[i]] <- cur_brew
}

all_breweries <- bind_rows(final_list)

# get our missing values as NA
all_breweries[all_breweries == "-"] <- NA

# remove the phone number tag from the address field for geocoding
all_breweries$address <- gsub(" phone: \\(?\\d{3}\\)?[.-]? *\\d{3}[.-]? *[.-]?\\d{4}", "", all_breweries$address)
all_breweries$address <- gsub("\\(?\\d{3}\\)?[.-]? *\\d{3}[.-]? *[.-]?\\d{4}", "", all_breweries$address)
all_breweries$address <- gsub("\\(?\\d{3}\\)?[.-]? *\\d{3}[.-]? *[.-]?BREW", "", all_breweries$address)
all_breweries$address <- gsub("\\(?\\d{3}\\)?[.-]? *\\d{3}[.-]? *[.-]?BEER", "", all_breweries$address)

all_breweries$brewery_rating <- as.numeric(all_breweries$brewery_rating)
all_breweries$num_reviews <- as.numeric(all_breweries$num_reviews)
all_breweries$beer_avg <- as.numeric(all_breweries$beer_avg)
all_breweries$num_beers <- as.numeric(all_breweries$num_beers)


library(htmlwidgets)
library(leaflet)
library(ggmap)

# This function geocodes a location (find latitude and longitude) using the Google Maps API
geo <- geocode(location = all_breweries$address[1:2000], output="latlon", source="google")

# add those coordinates to our dataset
all_breweries$lon <- NA
all_breweries$lat <- NA

all_breweries$lon[1:2000] <- geo$lon
all_breweries$lat[1:2000] <- geo$lat

save(all_breweries, file = "all_breweries.RData")


##### Add more lat/lon
library(ggmap)
load("all_breweries.RData")
range <- 4901:5686

geo <- geocode(location = all_breweries$address[range], output = "latlon", source = "google")

all_breweries$lon[range] <- geo$lon
all_breweries$lat[range] <- geo$lat

save(all_breweries, file = "all_breweries.RData")


### Get city lat/lon
library(dplyr)
city_codes <- all_breweries %>%
  mutate(city_state = paste0(city, ", ", state)) %>%
  select(city_state) %>%
  unique()

library(ggmap)
load("city_codes.RData")
range <- which(is.na(city_codes$lat))

geo <- geocode(location = city_codes$city_state[range], output = "latlon", source = "google")

city_codes$lon[range] <- geo$lon
city_codes$lat[range] <- geo$lat

save(city_codes, file = "city_codes.RData")


library(dplyr)
load("all_breweries.RData")
load("city_codes.RData")

city_codes <- city_codes %>%
  rename(city_lon = lon, city_lat = lat)

all_breweries <- all_breweries %>%
  mutate(full_city = paste0(city, ", ", state)) %>%
  left_join(city_codes, by = c("full_city" = "city_state"))

save(all_breweries, file = "all_breweries.RData")
