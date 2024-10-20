# Garmin Goal Tracker

Hey there, fitness enthusiast! 👋 Welcome to the Garmin Goal Tracker, your new best friend for keeping tabs on your running or cycling progress.

## What's this all about?

This Flutter app is designed to help you visualize and track your Garmin activity data. It pulls info from your Garmin account and displays it in a neat, easy-to-understand format. Perfect for when you're aiming for that yearly 1000km goal or just want to see how you're doing week by week.

## Features

- **Yearly Progress**: See how close you are to hitting that 1000km yearly goal.
- **Weekly Challenges**: Set weekly goals and watch your streak grow as you crush them.
- **Monthly Breakdown**: Check out a bar chart showing your activity for the last 12 months.
- **Dark Mode**: Because who doesn't love a good dark mode?

## Getting Started

1. Clone this repo
2. Run `flutter pub get` to grab all the dependencies
3. Create a `.env` file in the root directory and add your Garmin API key:
   ```
   API_KEY=your_api_key_here
   ```
4. Fire up the app with `flutter run`

## Tech Stack

- Flutter for the UI
- http package for API calls
- fl_chart for those sweet, sweet graphs
- flutter_dotenv for keeping our API key safe
- shared_preferences for local data storage

## Contributing

Found a bug? Have an idea for a cool new feature? We're all ears! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Happy tracking! 🏃‍♂️🚴‍♀️