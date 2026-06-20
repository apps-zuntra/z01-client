const ONESIGNAL_APP_ID = '8ba49c7c-97fb-4410-8354-ccb8dd2abfb5';
const ONESIGNAL_REST_API_KEY = 'YOUR_ONESIGNAL_REST_API_KEY';

async function testPush() {
  try {
    const userId = "3fe7c175-ab65-4c8b-8ce4-3618720a24a5"; // old subscribed user

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        target_channel: "push",
        include_aliases: {
          external_id: ["298a31c8-84af-4350-a4b5-d63370999015"]
        },
        headings: { en: 'Test from backend' },
        contents: { en: 'This is a manual test push!' },
        channel_for_external_user_ids: 'push'
      })
    });
    
    const data = await response.json();
    console.log("Success:", data);
  } catch (error) {
    console.error("Failed:", error);
  }
}

testPush();
