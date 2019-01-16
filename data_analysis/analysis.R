# locate data file
path <- file.path("I:","R", "Data_Analysis", "Brain Drain")
file <- list.files(path)
data.path <- paste(path, file, sep = "/")

library(tidyverse)

df <- read_csv(data.path, skip = 6)
column.names <- c("run_number",
                  "scholarship-plus-pg",
                  "tolerance-native_abr",
                  "tolerance-native-ina",
                  "scholarship-plus-ug",
                  "step",
                  "students_UG_INA",
                  "students_UG_ABR",
                  "students_PG_INA",
                  "students_PG_ABR",
                  "students_HS_INA",
                  "students_HS_ABR",
                  "patents",
                  "gdp_fund")
colnames(df) <- column.names

# analyze step number each scenario
df %>% 
  group_by(run_number) %>%
  summarise(n = length(run_number)) %>%
  summary()

# Visualization of simulation result
df %>%
  filter(step == 1080) %>%
  ggplot(aes(x = students_HS_ABR, y = students_HS_INA, 
             color = factor(`scholarship-plus-pg`))) +
  geom_point()

df %>%
  filter(step == 1080) %>%
  ggplot(aes(x = patents, y = gdp_fund, 
             color = factor(`scholarship-plus-pg`))) +
  geom_point()

df %>%
  filter(step == 1080) %>%
  ggplot(aes(x = patents, y = students_HS_ABR, 
             color = factor(`scholarship-plus-pg`))) +
  geom_point()

df %>%
  filter(step == 1080) %>%
  ggplot(aes(x = patents, y = students_HS_INA, 
             color = factor(`scholarship-plus-pg`))) +
  geom_point()
