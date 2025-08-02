from ytmusicapi import YTMusic

print("Starting YouTube Music setup...")
print("A browser window will open for you to log in and grant permissions.")
print("After logging in, copy the code from the browser and paste it into the console.")

try:
    YTMusic.setup(filepath='oauth.json')
    print("\nSetup complete! 'oauth.json' has been created successfully.")
    print("You can now start the main server by running 'python main.py'")
except Exception as e:
    print(f"\nAn error occurred during setup: {e}")
    print("Please try running the setup again.")
