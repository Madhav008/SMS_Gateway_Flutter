# my_sms

This is a simple flutter app that sends and receives SMS using local computer as server
The app currently only works on Windows and Linux
The computer needs to have a working internet connection and a phone connected to the computer

## API Endpoints

### POST /sms

Send SMS to the given phone number

- body:
  - phone_number: string
  - message: string

### GET /sms

Get all received SMS

- query:
  - phone_number: string

### GET /sms/:id

Get the SMS with the given ID

- path:
  - id: string

### DELETE /sms/:id

