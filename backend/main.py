from fastapi import FastAPI, HTTPException, Query
from ytmusicapi import YTMusic, OAuthCredentials
import os
import json

app = FastAPI()

# Global variable to hold the ytmusic instance
ytmusic = None

# These are the default credentials used by the ytmusicapi library's setup function.
# Using them here ensures consistency between setup and server initialization.
CLIENT_ID = "911978298422-33da6nn25i2picd89c1vg0ignh5t21bb.apps.googleusercontent.com"
CLIENT_SECRET = "GOCSPX-212s2n8321i2d-g2981212s"

def get_ytmusic_instance():
    """
    Initializes the YTMusic instance using the oauth.json file
    and the required OAuth credentials.
    """
    global ytmusic
    if ytmusic is None:
        oauth_filepath = 'oauth.json'
        if not os.path.exists(oauth_filepath):
            raise RuntimeError(
                "ERROR: 'oauth.json' not found. "
                "Please run 'python setup_oauth.py' to authenticate."
            )
        
        try:
            # Correct initialization using both the file and the credentials
            credentials = OAuthCredentials(client_id=CLIENT_ID, client_secret=CLIENT_SECRET)
            ytmusic = YTMusic(oauth_filepath, oauth_credentials=credentials)
            
            # Test the authentication
            ytmusic.get_library_playlists(limit=1)
            print("Successfully authenticated using 'oauth.json'.")

        except Exception as e:
            print(f"ERROR: Failed to authenticate with 'oauth.json'. It may be invalid or expired. Error: {e}")
            raise RuntimeError(
                "Please delete 'oauth.json' and run 'python setup_oauth.py' again."
            )
            
    return ytmusic

@app.on_event("startup")
async def startup_event():
    """
    On startup, initialize the YTMusic instance.
    If it fails, the server will not start, and a clear error will be printed.
    """
    try:
        get_ytmusic_instance()
    except RuntimeError as e:
        print(str(e))
        # In a real production scenario, you might want to exit the process
        # For this use case, we'll let it run but endpoints will fail.
        # A better approach is to ensure setup is done before running the app.
        pass


@app.get("/")
def read_root():
    return {"message": "Welcome to the Mirei YouTube Music API"}

@app.get("/search")
async def search(query: str, limit: int = 20):
    """
    Search for songs, albums, artists, and playlists.
    """
    instance = get_ytmusic_instance()
    try:
        search_results = instance.search(query, limit=limit)
        return search_results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/library/playlists")
async def get_library_playlists():
    instance = get_ytmusic_instance()
    if instance is None:
        raise HTTPException(status_code=503, detail="Authentication not configured. Please run setup.")
    try:
        playlists = instance.get_library_playlists()
        return playlists
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication required or failed: {e}")

@app.get("/library/liked")
async def get_liked_songs(limit: int = 100):
    instance = get_ytmusic_instance()
    if instance is None:
        raise HTTPException(status_code=503, detail="Authentication not configured. Please run setup.")
    try:
        liked_songs = instance.get_liked_songs(limit=limit)
        return liked_songs
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication required or failed: {e}")

@app.get("/stream_url")
async def get_stream_url(videoId: str):
    """
    This endpoint is a placeholder. yt-dlp or a similar tool
    is needed to get the actual stream URL. ytmusicapi does not provide this directly.
    """
    return {"message": "Stream URL generation is not implemented yet."}

if __name__ == "__main__":
    import uvicorn
    print("Starting Mirei YouTube Music API...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
