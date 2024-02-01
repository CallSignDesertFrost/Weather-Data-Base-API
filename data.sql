CREATE USER weather_user IDENTIFIED BY weather_password;
GRANT CONNECT, RESOURCE TO weather_user;

CREATE TABLE weather_data (
    id NUMBER PRIMARY KEY,
    city_name VARCHAR2(255),
    temperature NUMBER,
    humidity NUMBER,
    pressure NUMBER,
    weather_description VARCHAR2(255),
    timestamp TIMESTAMP
);

CREATE OR REPLACE PROCEDURE fetch_weather_data (p_city_name IN VARCHAR2) IS
    v_response_body CLOB;
    v_http_request UTL_HTTP.REQ;
    v_http_response UTL_HTTP.RESP;
    v_api_key VARCHAR2(255) := 'your_api_key_here';
    v_api_url VARCHAR2(255) := 'http://api.openweathermap.org/data/2.5/weather?q=' || p_city_name || '&appid=' || v_api_key;
BEGIN
    v_http_request := UTL_HTTP.BEGIN_REQUEST(v_api_url);
    UTL_HTTP.SET_HEADER(v_http_request, 'User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36');
    v_http_response := UTL_HTTP.GET_RESPONSE(v_http_request);

    IF UTL_HTTP.GET_STATUS_CODE(v_http_response) = 200 THEN
        UTL_HTTP.READ_TEXT(v_http_response, v_response_body);
        INSERT INTO weather_data (city_name, temperature, humidity, pressure, weather_description, timestamp)
        VALUES (
            JSON_VALUE(v_response_body, '$.name'),
            JSON_VALUE(v_response_body, '$.main.temp') - 273.15,
            JSON_VALUE(v_response_body, '$.main.humidity'),
            JSON_VALUE(v_response_body, '$.main.pressure'),
            JSON_VALUE(v_response_body, '$.weather[0].description'),
            CURRENT_TIMESTAMP
        );
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Failed to fetch weather data: ' || UTL_HTTP.GET_STATUS_LINE(v_http_response));
    END IF;

    UTL_HTTP.END_RESPONSE(v_http_response);
EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN
        UTL_HTTP.END_RESPONSE(v_http_response);
    WHEN OTHERS THEN
        UTL_HTTP.END_RESPONSE(v_http_response);
        RAISE;
END fetch_weather_data;
/

BEGIN
    fetch_weather_data('London');
END;
/