# Platform assessment

Touch Grass currently needs the shared `FentonDesignSystem` Swift package, not a deployed Platform process.
The iPhone app stores preferences and progress in its sandbox, reads EventKit locally, schedules local
notifications, and speaks exercise instructions with Apple's native speech system. WeatherKit can run
on-device with Apple's entitlement. None of these require a server, identity tenant, database, queue,
SMS sender, or always-running agent. There is consequently no server healthz endpoint to deploy or check.

The iPhone and Mac keep separate local histories. Cross-device sync is a separate product capability;
it is not implied by reusing the design system. A future server should be justified by an explicit sync,
remote notification, or agent requirement and reuse Platform authentication and deployment contracts then.

## iOS scheduling boundary

The app queues up to 60 one-shot notifications across the next 14 days, excluding selected-calendar
meetings and respecting work days/hours. Foreground activation and observed EventKit changes rebuild
the queue. iOS cannot continuously run the Mac menu-bar timer while the app is suspended. Changes made
while it is suspended become reflected when reopened. The Settings screen explains this limitation.
