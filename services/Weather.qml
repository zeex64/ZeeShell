pragma Singleton

import Quickshell
import QtQuick
import qs.config
import "Http.js" as Http

// Open-Meteo forecast. Location is either looked up from the public IP or
// taken from the city saved in settings.
Singleton {
    id: root

    property bool ready: false
    property bool loading: false
    property string error: ""
    property string city: ""
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property real wind: 0
    property int code: 0
    property bool isDay: true
    property var daily: [] // { day, code, max, min }
    property var hourly: [] // { hour, code, temp }

    readonly property string unit: Config.weather.fahrenheit ? "°F" : "°C"
    readonly property string icon: iconFor(code, isDay)
    readonly property string description: describe(code)
    readonly property string tempText: ready ? Math.round(temp) + "°" : "--°"

    function iconFor(c, day) {
        if (c === 0) return day ? "sun" : "moon";
        if (c <= 2) return day ? "cloud-sun" : "cloud-moon";
        if (c === 3) return "cloud";
        if (c === 45 || c === 48) return "cloud-fog";
        if (c >= 51 && c <= 67) return "cloud-rain";
        if (c >= 71 && c <= 77) return "cloud-snow";
        if (c >= 80 && c <= 82) return "cloud-rain";
        if (c === 85 || c === 86) return "cloud-snow";
        if (c >= 95) return "cloud-lightning";
        return "cloud";
    }

    function describe(c) {
        const m = {
            0: "Clear sky", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog",
            51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
            80: "Light showers", 81: "Showers", 82: "Violent showers", 85: "Snow showers", 86: "Heavy snow showers",
            95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail"
        };
        return m[c] || "Unknown";
    }

    function refresh() {
        if (!Config.ready) return;
        loading = true;
        if (Config.weather.autoLocate) {
            Http.get("https://get.geojs.io/v1/ip/geo.json", d => {
                city = d.city || d.region || d.country || "";
                fetch(parseFloat(d.latitude), parseFloat(d.longitude));
            }, e => { error = "Could not find location"; loading = false; });
        } else if (Config.weather.city !== "") {
            city = Config.weather.city;
            fetch(Config.weather.latitude, Config.weather.longitude);
        } else {
            error = "Set a location in settings";
            loading = false;
        }
    }

    function fetch(lat, lon) {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=7&forecast_hours=12"
            + (Config.weather.fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");
        Http.get(url, d => {
            const c = d.current;
            temp = c.temperature_2m; feels = c.apparent_temperature; humidity = c.relative_humidity_2m;
            wind = c.wind_speed_10m; code = c.weather_code; isDay = c.is_day === 1;
            const days = [];
            for (let i = 0; i < d.daily.time.length; i++)
                days.push({ day: new Date(d.daily.time[i] + "T12:00").toLocaleDateString(Qt.locale(), "ddd"), code: d.daily.weather_code[i], max: Math.round(d.daily.temperature_2m_max[i]), min: Math.round(d.daily.temperature_2m_min[i]) });
            daily = days;
            const hours = [];
            for (let i = 0; i < Math.min(12, d.hourly.time.length); i++)
                hours.push({ hour: d.hourly.time[i].substring(11, 13), code: d.hourly.weather_code[i], temp: Math.round(d.hourly.temperature_2m[i]) });
            hourly = hours;
            error = "";
            ready = true;
            loading = false;
        }, e => { error = "Weather unavailable (" + e + ")"; loading = false; });
    }

    // City lookup for the settings page. cb receives [{ name, detail, latitude, longitude }].
    function search(query, cb) {
        Http.get("https://geocoding-api.open-meteo.com/v1/search?count=6&name=" + encodeURIComponent(query), d => {
            cb((d.results || []).map(r => ({ name: r.name, detail: [r.admin1, r.country].filter(x => x).join(", "), latitude: r.latitude, longitude: r.longitude })));
        }, e => cb([]));
    }

    function setCity(r) {
        Config.weather.city = r.name;
        Config.weather.latitude = r.latitude;
        Config.weather.longitude = r.longitude;
        Config.weather.autoLocate = false;
        refresh();
    }

    Timer {
        interval: Math.max(5, Config.weather.refreshMinutes) * 60000
        repeat: true
        running: Config.ready
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Config.weather
        function onFahrenheitChanged() { root.refresh(); }
        function onAutoLocateChanged() { root.refresh(); }
    }
}
