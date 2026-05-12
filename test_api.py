import requests
import json

url = "https://lwijsmfxjibarnqeefnp.supabase.co/rest/v1/vendor_listings?select=*"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3aWpzbWZ4amliYXJucWVlZm5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODA2NzksImV4cCI6MjA4Nzc1NjY3OX0.134fVKQ9RgbXE-cT8YyFB8M26w8lejvGqfee-yshp98",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3aWpzbWZ4amliYXJucWVlZm5wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODA2NzksImV4cCI6MjA4Nzc1NjY3OX0.134fVKQ9RgbXE-cT8YyFB8M26w8lejvGqfee-yshp98"
}

try:
    response = requests.get(url, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Data: {response.text}")
except Exception as e:
    print(f"Error: {e}")
