# Activity Suggestion Decision Tree

> **Status: ✅ IMPLEMENTED** - This document describes the decision tree logic that has been implemented in `Managers/ActivitySuggestionEngine.swift`. The test scenarios are covered in `TouchGrassTests/Integration/ActivitySuggestionEngineTests.swift`.

## Goal
Reduce decision fatigue by suggesting ONE optimal activity based on context, while maintaining user agency to choose alternatives. The system should be aware of the user's entire day schedule and adapt suggestions accordingly.

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

- **Available Time Windows**
  - **Immediate**: Time until next calendar event
  - **Break Categories**:
    - Micro (<2 min): Eye rest, breathing, quick stretch
    - Quick (2-5 min): Single focused exercise
    - Standard (5-10 min): Full routine or walk
    - Extended (10-15 min): Outdoor time or multi-exercise set
    - Long (>15 min): Full outdoor break or meditation session
  - **Smart Sizing**: Never suggest activities longer than available time

- **Day Schedule Context**
  - **Meeting Density**: 
    - Light day (<3 meetings): Can afford longer breaks
    - Normal day (3-5 meetings): Standard breaks
    - Heavy day (>5 meetings): Prioritize quick, high-impact breaks
  - **Break Distribution**:
    - Morning breaks so far
    - Afternoon breaks planned
    - Time since last substantial break (>5 min)
    - Remaining break opportunities today
  - **Energy Management**:
    - Front-load energizing activities on heavy days
    - Save relaxation for end of meeting-heavy periods
    - Balance throughout the day

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

1. **Time Constraint Filter (ALWAYS FIRST)**
   ```
   available_time = min(time_until_next_meeting, max_break_duration)
   
   IF (available_time < 2 minutes)
   → FILTER: Only micro activities (breathing, eye rest)
   
   IF (available_time < 5 minutes) 
   → FILTER: Exclude routines, outdoor walks
   
   IF (available_time < 10 minutes)
   → FILTER: Exclude extended routines
   ```

2. **Critical Time Windows**
   ```
   IF (next_meeting in 3-7 minutes) AND (been sitting 90+ min)
   → SUGGEST: Quick energizing activity to prep for meeting
   
   IF (just finished 2+ hour meeting block)
   → SUGGEST: Extended break if possible (walk, full routine)
   
   IF (last substantial break >3 hours ago)
   → SUGGEST: Prioritize any movement activity that fits
   ```

3. **Weather Window of Opportunity**
   ```
   IF (weather is "perfect") AND (haven't done outdoor today) 
      AND (daylight) AND (have 10+ minutes)
   → SUGGEST: Touch Grass (with enthusiasm: "Beautiful day outside!")
   ```

4. **Critical Physical Needs**
   ```
   IF (sitting > 2 hours continuously)
   → SUGGEST: Movement activity (walk, hip rotations, standing stretches)
   
   IF (hunched posture time > 90 min) 
   → SUGGEST: Posture correction (chin tucks, back extension)
   ```

5. **Day Schedule Awareness**
   ```
   meeting_density = count_meetings_today()
   breaks_taken = count_substantial_breaks_today()
   
   IF (meeting_density > 5) AND (breaks_taken < 2)
   → SUGGEST: High-impact quick break (maximize limited time)
   
   IF (afternoon) AND (only had micro-breaks so far)
   → SUGGEST: Substantial movement break if time allows
   
   IF (end of day approaching) AND (outdoors not done) AND (weather good)
   → SUGGEST: Last chance for outdoor time
   ```

6. **Time-of-Day Optimization**
   ```
   IF (time is 1-3pm) AND (energy likely low)
   → SUGGEST: Energizing activity (walk, standing exercises, fresh air)
   
   IF (time is 9-11am) AND (weather is good)
   → SUGGEST: Outdoor activity to set positive day tone
   
   IF (time is 4-6pm) AND (high meeting day)
   → SUGGEST: Calming activity (breathing, meditation, gentle stretches)
   ```

7. **Variety & Balance**
   ```
   activities_today = get_completed_activities_today()
   
   IF NOT activities_today.contains("physical")
   → SUGGEST: Movement/exercise
   
   IF NOT activities_today.contains("mental")
   → SUGGEST: Breathing/meditation
   
   IF NOT activities_today.contains("outdoor") AND weather_ok
   → SUGGEST: Touch grass/outdoor walk
   ```

8. **Smart Defaults by Context**
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