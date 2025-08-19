# Activity Suggestion Decision Tree

## Goal
Reduce decision fatigue by suggesting ONE optimal activity based on context, while maintaining user agency to choose alternatives.

## Input Factors

### 1. Environmental Context
- **Weather Data**
  - Temperature (cold <50°F, nice 50-75°F, hot >75°F)
  - Conditions (sunny, cloudy, rainy, snowy)
  - Daylight (sunrise/sunset times)
- **Location**
  - At home vs office (if detectable)
  - Indoor/outdoor feasibility

### 2. Temporal Context  
- **Time of Day Buckets**
  - Early Morning (6-9am): Body waking up
  - Mid-Morning (9-12pm): Peak focus time
  - Lunch (12-1pm): Mid-day break
  - Early Afternoon (1-3pm): Post-lunch dip
  - Late Afternoon (3-5pm): Second wind
  - Evening (5-7pm): Wind down
- **Available Time**
  - Quick (<3 min): Micro-breaks
  - Short (3-5 min): Single activities  
  - Medium (5-10 min): Full routines
  - Long (>10 min): Extended activities

### 3. User History
- **Today's Activities**
  - What's been completed
  - Time since each activity
  - Variety balance (physical/mental/outdoor)
- **Recent Patterns**
  - Last 7 days activity frequency
  - Success rate (completed vs skipped)
  - Time-of-day preferences

### 4. Physical/Mental State (Inferred)
- **Energy Level**
  - Low: Early morning, post-lunch (1-3pm)
  - Medium: Mid-morning, late afternoon
  - High: Peak hours (10-11am, 3-4pm)
- **Stress Indicators**
  - Meeting density in calendar
  - Time since last break
  - Day of week (Mon/Fri vs mid-week)

## Decision Algorithm

### Priority Order (first match wins):

1. **Weather Window of Opportunity**
   ```
   IF (weather is "perfect") AND (haven't done outdoor today) AND (daylight)
   → SUGGEST: Touch Grass (with enthusiasm: "Beautiful day outside!")
   ```

2. **Critical Physical Needs**
   ```
   IF (sitting > 2 hours continuously)
   → SUGGEST: Movement activity (walk, hip rotations, standing stretches)
   
   IF (hunched posture time > 90 min) 
   → SUGGEST: Posture correction (chin tucks, back extension)
   ```

3. **Time-of-Day Optimization**
   ```
   IF (time is 1-3pm) AND (energy likely low)
   → SUGGEST: Energizing activity (walk, standing exercises, fresh air)
   
   IF (time is 9-11am) AND (weather is good)
   → SUGGEST: Outdoor activity to set positive day tone
   
   IF (time is 4-6pm) AND (high meeting day)
   → SUGGEST: Calming activity (breathing, meditation, gentle stretches)
   ```

4. **Variety & Balance**
   ```
   activities_today = get_completed_activities_today()
   
   IF NOT activities_today.contains("physical")
   → SUGGEST: Movement/exercise
   
   IF NOT activities_today.contains("mental")
   → SUGGEST: Breathing/meditation
   
   IF NOT activities_today.contains("outdoor") AND weather_ok
   → SUGGEST: Touch grass/outdoor walk
   ```

5. **Smart Defaults by Context**
   ```
   IF (available_time < 3 min)
   → SUGGEST: Quick reset (breathing, eye rest, neck rolls)
   
   IF (haven't moved in 90+ min)
   → SUGGEST: Movement priority
   
   ELSE
   → SUGGEST: Least recently done activity that fits time window
   ```

## Scoring System (Alternative Approach)

Each activity gets a score based on:
- **Recency**: -10 points per day since last done (max -70)
- **Weather Match**: +50 if perfect weather for outdoor, -50 if bad weather
- **Time Match**: +30 if ideal time of day for this activity
- **Variety**: +40 if different category than last 2 activities  
- **Energy Match**: +20 if matches current energy needs
- **Duration Fit**: +20 if fits available time, -30 if doesn't fit
- **Streak Bonus**: +10 if would continue a streak

Highest scoring activity wins.

## Test Scenarios

### Scenario 1: Perfect Spring Morning
- Time: 10am Tuesday
- Weather: 68°F, sunny
- Last outdoor: Yesterday
- Available time: 10 minutes
- **Expected**: Touch Grass

### Scenario 2: Rainy Afternoon Slump  
- Time: 2:30pm Wednesday
- Weather: 45°F, heavy rain
- Sitting for: 2 hours
- Energy: Low (post-lunch)
- **Expected**: Energizing indoor exercise

### Scenario 3: Back-to-Back Meetings
- Time: 4pm Thursday  
- Weather: Normal
- Meetings: 3 hours straight, more coming
- Stress: High
- **Expected**: Breathing exercise or meditation

### Scenario 4: Quick Break
- Time: 11am Monday
- Available time: 2 minutes only
- Last activity: 1 hour ago
- **Expected**: Quick desk stretches or eye rest

### Scenario 5: Evening Wind-Down
- Time: 5:30pm Friday
- Weather: Nice but getting dark
- Day's activities: Mostly physical
- **Expected**: Meditation or breathing exercise

## Implementation Notes

1. **Weather API**: Use simple service (OpenWeatherMap or Apple WeatherKit)
2. **Caching**: Cache weather for 30 min to avoid API spam
3. **Learning**: Track completion rates to weight suggestions over time
4. **Explanations**: Include brief "why" with suggestion ("Perfect weather outside!" or "Time to move after 2 hours")
5. **Fallback**: Always have a safe default (walking) if logic fails

## Future Enhancements

1. Personal preference learning
2. Health app integration (standing hours, etc.)
3. Seasonal adjustments
4. Team/social features ("3 colleagues are walking now")
5. Customizable factors (user can set priorities)