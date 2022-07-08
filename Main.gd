extends Node

#Variables
var city 
var state
var stateCode
var zipCode
var lat
var long
var fullURL
var ForecastURL
var HForecastURL
var baseURL = "https://api.weather.gov/points/"
var GeoAPI = "http://ip-api.com/json/"
var ImpUnits = "?units=us"
var CatForecastURL 
var WeeklyForecastResult
var HourlyForecastResult
var DetailedForecastNumebr
var CityState
var ZoneURL
var ZoneID
var AlertBase = "https://api.weather.gov/alerts/active/zone/"
var ActiveAlertURL
var Alerts
var AlertCount
var EPAKey
var EPABaseURL = "https://www.airnowapi.org/"
var EPAObsURL = "aq/observation/zipCode/current/?format=application/json&zipCode="
var EPADist = "&distance=50"
var EPAAPIKey = "&API_KEY="

func _ready():
	print("Program Starting")
	#Set Alert Display to be invisble
	$GUI/AlertDisplay.visible = false
	#Show Forecasts Page
	$GUI/Forecasts.visible = true
	#More alert stuff. Invisible to start.
	$GUI/Forecasts/Window/NowCast/Alert.visible = false
	#Hide server failure message at start.
	$GUI/ServerFailure.visible = false
	#Hide Settings Menu
	$GUI/Settings.visible = false
	#Hide Air Quality Page
	$GUI/AirQuality.visible = false
	findLocation()
	#Loads Settings
	LoadSettings()
	
func findLocation():
	#Request location data from the ip-api API
	print("Finding Location...")
	$NetworkController/Location.request(GeoAPI)

func _on_Location_request_completed(result, response_code, headers, body):
	#ip-api response.
	print("Location Found.")
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result.status)
	#Validate return data
	if json.result.status == "success":
		#If a request is successful, do this:
		city = json.result.city
		state = json.result.regionName
		stateCode = json.result.region
		zipCode = json.result.zip
		lat = json.result.lat
		long = json.result.lon
		#lat = 33.4025 #For Testing. 
		#long = -84.522 #For Testing
		fullURL = str(baseURL, lat, ",", long)
		CityState = str(city,"  ",state)
		$GUI/Forecasts/Window/Header/Location.text = String(CityState)
		print("Lat:")
		print(lat)
		print("Long:")
		print(long)
		print("Full URL:")
		print(fullURL)
		print("Fetching Forecast URLs...")
		getGridPoints()
	else:
		print("Location API Server Failure")
		#Otherwise, display server failure screen
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = json.result.status

func getGridPoints():
	#Find NWS gridpoints using the ip-api data
	$NetworkController/Forecast.request(fullURL)

func _on_Forecast_request_completed(result, response_code, headers, body):
	print("Forecast URLs Returned.")
	var GPjson = JSON.parse(body.get_string_from_utf8())
	#Validate return data
	if response_code == 200:
		#Build URLs needed for forecast requests
		ForecastURL = GPjson.result.properties.forecast
		HForecastURL = GPjson.result.properties.forecastHourly
		CatForecastURL = str(ForecastURL,ImpUnits)
		ZoneURL = GPjson.result.properties.county
		print("Forecast URL:")
		print(ForecastURL)
		print("Hourly URL:")
		print(HForecastURL)
		print("Full Weekly URL:")
		print(CatForecastURL)
		print("Zone URL:")
		print(ZoneURL)
		print("Getting Weekly Forecast")
		getHourlyForecast()
		getWeeklyForecast()
		getZoneID()
	else:
		print("Forecast URL Server Error")
		#Display server failure page
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func getHourlyForecast():
	$NetworkController/HoulyForecast.request(HForecastURL)

func getWeeklyForecast():
	$NetworkController/WeeklyForecast.request(CatForecastURL)

func getZoneID():
	$NetworkController/ZoneIDRequest.request(ZoneURL)

func _on_HoulyForecast_request_completed(result, response_code, headers, body):
	var HourlyForecastJSON = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		HourlyForecastResult = HourlyForecastJSON.result.properties.periods
		PrintHourlyResults()
	else:
		print("Hourly Forecast Server Failure")
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func _on_WeeklyForecast_request_completed(result, response_code, headers, body):
	var WeeklyForecastJSON = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		WeeklyForecastResult = WeeklyForecastJSON.result.properties.periods
		PrintWeeklyResults()
	else:
		print("Weekly Forecast Server Failure")
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func _on_ZoneIDRequest_request_completed(result, response_code, headers, body):
	var ZoneIDRequestResult = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		ZoneID = ZoneIDRequestResult.result.properties.id
		ActiveAlertURL = str(AlertBase,ZoneID)
		print("ZoneID:")
		print(ZoneID)
		print("Active Alerts URL:")
		print(ActiveAlertURL)
		getAlerts()
	else:
		print("Zone ID Request Server Failure")
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func getAlerts():
	$NetworkController/AlertRequest.request(ActiveAlertURL)

func _on_AlertRequest_request_completed(result, response_code, headers, body):
	var AlertJSON = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		Alerts = AlertJSON.result.features
		AlertHandler()
	else:
		print("Alert Request Server Failure")
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func AlertHandler():
	var AlertNumberUpdate
	var WA = " Weather Alerts"
	var WAS = " Weather Alert"
	print("Alerts:")
	if Alerts == []:
		print("No Alerts")
		$GUI/Forecasts/Window/NowCast/Alert.visible = false
	else: 
		$GUI/Forecasts/Window/NowCast/Alert.visible = true
		print("ALERT!")
		AlertCount = Alerts.size()
		#AlertCount = 1 #Testing.
		print("Alert Count:")
		print(AlertCount)
		AlertNumberUpdate = get_tree().get_root().get_node("Main/GUI/AlertDisplay/Body/Header")
		if AlertCount == 1:
			AlertNumberUpdate.text = str(AlertCount,WAS)
		else:
			AlertNumberUpdate.text = str(AlertCount,WA)
		alertProcessing()

func alertProcessing():
	var i = AlertCount
	var Counter = 0
	var AlertNumber = 1
	var scene = ResourceLoader.load("res://AlertInfo.tscn")
	var path = get_tree().get_root().get_node("Main/GUI/AlertDisplay/Body/AlertScroll/Target")
	print(path)
	print(scene)
	print(i)
		
	for number in range(i):
		#Make Instance
		#print("Loop:", Counter)
		var NewInstance = scene.instance()
		NewInstance.name = "AlertInfo" + String(Counter)
		path.add_child(NewInstance)
		#print("New Instance Name:")
		#print(NewInstance.name)
		NewInstance.get_node("Intro/AlertNum").text = String(AlertNumber)
		NewInstance.get_node("Headline/HLabel").text = String(Alerts[Counter].properties.headline)
		NewInstance.get_node("AlertInfo1/A1Status").text = String(Alerts[Counter].properties.severity)
		NewInstance.get_node("AlertInfo2/A2Status").text = String(Alerts[Counter].properties.certainty)
		NewInstance.get_node("AlertInfo3/A3Status").text = String(Alerts[Counter].properties.urgency)
		NewInstance.get_node("AlertInfo4/A4Status").text = String(Alerts[Counter].properties.event)
		NewInstance.get_node("AlertInfo5/A5Status").text = String(Alerts[Counter].properties.response)
		NewInstance.get_node("Desc").text = String(Alerts[Counter].properties.description)
		print("Instructions:")
		print(Alerts[Counter].properties.instruction)
		
		if Alerts[Counter].properties.instruction == null:
			print("NULL!!!!")
			NewInstance.get_node("Ins").text = "No Further Instructions at this Time"
		else:
			print("Instructions Present")
			NewInstance.get_node("Ins").text = String(Alerts[Counter].properties.instruction)
		
		Counter = Counter + 1
		AlertNumber = AlertNumber + 1

func _on_Alert_pressed():
	$GUI/AlertDisplay.visible = true
	$GUI/Forecasts.visible = false

func _on_ForecastReturn_pressed():
	$GUI/AlertDisplay.visible = false
	$GUI/Forecasts.visible = true

func PrintHourlyResults():
	#NowCast
	$GUI/Forecasts/Window/NowCast/NowTemp/Temp.text = String(HourlyForecastResult[0].temperature)
	$GUI/Forecasts/Window/NowCast/NowTemp/Unit.text = String(HourlyForecastResult[0].temperatureUnit)
	$GUI/Forecasts/Window/NowCast/NowWind/WindSpeed.text = String(HourlyForecastResult[0].windSpeed)
	$GUI/Forecasts/Window/NowCast/NowWind/Direction.text = String(HourlyForecastResult[0].windDirection)
	$GUI/Forecasts/Window/NowCast/ShortCast.text = String(HourlyForecastResult[0].shortForecast)
	#Hourly Forecast for Next 155 Hours
	var Counter = 1
	var HourlyCount = HourlyForecastResult.size()
	var scene = ResourceLoader.load("res://T0.tscn")
	var path = get_tree().get_root().get_node("Main/GUI/Forecasts/Window/HourlyScroll/HourlyCast")
	var SepScene = ResourceLoader.load("res://VSeparator.tscn")
	print(path)
	print(scene)
	print(HourlyCount)
	print(Counter)
	
	for number in range(155):
		#print("Loop:", Counter)
		var NewInstance = scene.instance()
		var vInst = SepScene.instance()
		NewInstance.name = "T" + String(Counter)
		path.add_child(NewInstance)
		#print("New Instance Name:")
		#print(NewInstance.name)
		#Handle Time
		var DateTime = HourlyForecastResult[Counter].startTime
		var Date = DateTime.split("T")[0].split("-")
		var Time = DateTime.split("T")[1].trim_suffix("Z").split(":")
		var Year = Date[0]
		var Month = Date[1]
		var Day = Date[2]
		var Hour = Time[0]
		var Min = Time[1]
		var Sec = Time[2]
		Hour = int(Hour)
		
		#Convert from 24hr to 12hr.
		if Hour > 12:
			Hour = Hour - 12
			NewInstance.get_node("DateTime").text = str(Month, "/", Day, " ", Hour, ":", Min, "PM")
		elif Hour == 0:
			Hour = 12
			NewInstance.get_node("DateTime").text = str(Month, "/", Day, " ", Hour, ":", Min, "AM")
		elif Hour == 12:
			NewInstance.get_node("DateTime").text = str(Month, "/", Day, " ", Hour, ":", Min, "PM")
		else:
			NewInstance.get_node("DateTime").text = str(Month, "/", Day, " ", Hour, ":", Min, "AM")
		
		#Continue
		NewInstance.get_node("T0Temp/Temp").text = String(HourlyForecastResult[Counter].temperature)
		NewInstance.get_node("T0Temp/Unit").text = String(HourlyForecastResult[Counter].temperatureUnit)
		NewInstance.get_node("T0Wind/WindSpeed").text = String(HourlyForecastResult[Counter].windSpeed)
		NewInstance.get_node("T0Wind/Direction").text = String(HourlyForecastResult[Counter].windDirection)
		path.add_child(vInst)
		Counter = Counter + 1

func _on_CloseApp_pressed():
	get_tree().quit()

#Settings
func SaveSettings():
	#Save User Settings
	var file = File.new()
	file.open("user://MiniWeatherSettings.dat", File.WRITE)
	file.store_var(EPAKey)
	file.close()

func LoadSettings():
	#Load User Settings
	var file = File.new()
	file.open("user://MiniWeatherSettings.dat", File.READ)
	EPAKey = file.get_var()
	file.close()
	$GUI/Settings/Body/EPAKey/LineEdit.text = EPAKey

func _on_Settings_pressed():
	#Hide Everything, then show Settings page
	$GUI/Forecasts.visible = false
	$GUI/AlertDisplay.visible = false
	$GUI/Settings.visible = true

func _on_LineEdit_text_changed(new_text):
	EPAKey = new_text
	print("New Text:")
	print(EPAKey)

func _on_Return_pressed():
	SaveSettings()
	$GUI/Settings.visible = false
	$GUI/Forecasts.visible = true

#Air Quality
func _on_AirQuality_pressed():
	#Hide Everything
	$GUI/AlertDisplay.visible = false
	$GUI/Forecasts.visible = false
	#Show Air Quality Page
	$GUI/AirQuality.visible = true
	EPAQuery()

func EPAQuery():
	#Cat EPA API URL Request
	var EPAFullURL = str(EPABaseURL,EPAObsURL,zipCode,EPADist,EPAAPIKey,EPAKey)
	print("Full EPA API URL:")
	print(EPAFullURL)
	$NetworkController/EPAReq.request(EPAFullURL)

func _on_EPAReq_request_completed(result, response_code, headers, body):
	var EPAResult = JSON.parse(body.get_string_from_utf8())
	if response_code == 200:
		var EPAJson = EPAResult.result
		print(EPAJson)
		$GUI/AirQuality/Body/DateTimeObs/Date.text = String(EPAJson[0].DateObserved)
		$GUI/AirQuality/Body/DateTimeObs/Time.text = String(EPAJson[0].HourObserved)
		$GUI/AirQuality/Body/DateTimeObs/TimeZone.text = String(EPAJson[0].LocalTimeZone)
		$GUI/AirQuality/Body/Values/AQIValue/AQI2.text = String(EPAJson[0].AQI)
		$GUI/AirQuality/Body/Values/CatNumVal/CatNumber2.text = String(EPAJson[0].Category.Number)
		$GUI/AirQuality/Body/Values/CatNumVal/CatName.text = String(EPAJson[0].Category.Name)
		#Modulate CatName Color 
		if EPAJson[0].Category.Number == 1:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(0,1,0,1)
		elif EPAJson[0].Category.Number == 2:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(1,1,0,1)
		elif EPAJson[0].Category.Number == 3:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(1,0.65,0,1)
		elif EPAJson[0].Category.Number == 4:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(1,0,0,1)
		elif EPAJson[0].Category.Number == 5:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(0.63,0.13,0.94,1)
		elif EPAJson[0].Category.Number == 6:
			$GUI/AirQuality/Body/Values/CatNumVal/CatName.modulate = Color(1,0,1,1)
		#Convert HourObserved from 24h to 12h 
		var TimeStamp = EPAJson[0].HourObserved
		if TimeStamp > 12: 
			TimeStamp = TimeStamp - 12
			$GUI/AirQuality/Body/DateTimeObs/Time.text = String(TimeStamp)
			$GUI/AirQuality/Body/DateTimeObs/Time3.text = "PM"
		elif TimeStamp <= 12: 
			$GUI/AirQuality/Body/DateTimeObs/Time.text = String(TimeStamp)
			$GUI/AirQuality/Body/DateTimeObs/Time3.text = "AM"
	elif response_code == 401:
		$GUI/AirQuality.visible = false
		_on_Settings_pressed()
	else:
		print("EPA Request Server Failure")
		$GUI/Forecasts.visible = false
		$GUI/AlertDisplay.visible = false
		$GUI/AirQuality.visible = false
		$GUI/ServerFailure.visible = true
		$GUI/ServerFailure/Body/Response.text = String(response_code)

func _on_ReturnAQ_pressed():
	#Hide Air Quality Page, show Forecasts
	$GUI/AirQuality.visible = false
	$GUI/Forecasts.visible = true
	
func PrintWeeklyResults():
	$GUI/Forecasts/Window/WeeklyScroll.get_v_scrollbar().modulate = Color(0, 0, 0, 0) #Hide Scroll Bar
	$GUI/Forecasts/Window/HourlyScroll.get_h_scrollbar().modulate = Color(0, 0, 0, 0)
	$GUI/AlertDisplay/Body/AlertScroll.get_v_scrollbar().modulate = Color(0, 0, 0, 0) #Hide Scroll Bar
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/Date.text = String(WeeklyForecastResult[0].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/W0Temp/Temp.text = String(WeeklyForecastResult[0].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/W0Temp/Unit.text = String(WeeklyForecastResult[0].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/W0Wind/Speed.text = String(WeeklyForecastResult[0].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/W0Wind/Direction.text = String(WeeklyForecastResult[0].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W0/Forecast.text = String(WeeklyForecastResult[0].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/Date.text = String(WeeklyForecastResult[1].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/W0Temp/Temp.text = String(WeeklyForecastResult[1].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/W0Temp/Unit.text = String(WeeklyForecastResult[1].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/W0Wind/Speed.text = String(WeeklyForecastResult[1].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/W0Wind/Direction.text = String(WeeklyForecastResult[1].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W1/Forecast.text = String(WeeklyForecastResult[1].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/Date.text = String(WeeklyForecastResult[2].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/W0Temp/Temp.text = String(WeeklyForecastResult[2].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/W0Temp/Unit.text = String(WeeklyForecastResult[2].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/W0Wind/Speed.text = String(WeeklyForecastResult[2].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/W0Wind/Direction.text = String(WeeklyForecastResult[2].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W2/Forecast.text = String(WeeklyForecastResult[2].detailedForecast)

	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/Date.text = String(WeeklyForecastResult[3].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/W0Temp/Temp.text = String(WeeklyForecastResult[3].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/W0Temp/Unit.text = String(WeeklyForecastResult[3].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/W0Wind/Speed.text = String(WeeklyForecastResult[3].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/W0Wind/Direction.text = String(WeeklyForecastResult[3].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W3/Forecast.text = String(WeeklyForecastResult[3].detailedForecast)

	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/Date.text = String(WeeklyForecastResult[4].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/W0Temp/Temp.text = String(WeeklyForecastResult[4].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/W0Temp/Unit.text = String(WeeklyForecastResult[4].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/W0Wind/Speed.text = String(WeeklyForecastResult[4].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/W0Wind/Direction.text = String(WeeklyForecastResult[4].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W4/Forecast.text = String(WeeklyForecastResult[4].detailedForecast)

	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/Date.text = String(WeeklyForecastResult[5].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/W0Temp/Temp.text = String(WeeklyForecastResult[5].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/W0Temp/Unit.text = String(WeeklyForecastResult[5].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/W0Wind/Speed.text = String(WeeklyForecastResult[5].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/W0Wind/Direction.text = String(WeeklyForecastResult[5].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W5/Forecast.text = String(WeeklyForecastResult[5].detailedForecast)

	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/Date.text = String(WeeklyForecastResult[6].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/W0Temp/Temp.text = String(WeeklyForecastResult[6].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/W0Temp/Unit.text = String(WeeklyForecastResult[6].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/W0Wind/Speed.text = String(WeeklyForecastResult[6].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/W0Wind/Direction.text = String(WeeklyForecastResult[6].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W6/Forecast.text = String(WeeklyForecastResult[6].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/Date.text = String(WeeklyForecastResult[7].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/W0Temp/Temp.text = String(WeeklyForecastResult[7].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/W0Temp/Unit.text = String(WeeklyForecastResult[7].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/W0Wind/Speed.text = String(WeeklyForecastResult[7].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/W0Wind/Direction.text = String(WeeklyForecastResult[7].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W7/Forecast.text = String(WeeklyForecastResult[7].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/Date.text = String(WeeklyForecastResult[8].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/W0Temp/Temp.text = String(WeeklyForecastResult[8].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/W0Temp/Unit.text = String(WeeklyForecastResult[8].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/W0Wind/Speed.text = String(WeeklyForecastResult[8].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/W0Wind/Direction.text = String(WeeklyForecastResult[8].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W8/Forecast.text = String(WeeklyForecastResult[8].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/Date.text = String(WeeklyForecastResult[9].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/W0Temp/Temp.text = String(WeeklyForecastResult[9].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/W0Temp/Unit.text = String(WeeklyForecastResult[9].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/W0Wind/Speed.text = String(WeeklyForecastResult[9].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/W0Wind/Direction.text = String(WeeklyForecastResult[9].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W9/Forecast.text = String(WeeklyForecastResult[9].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/Date.text = String(WeeklyForecastResult[10].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/W0Temp/Temp.text = String(WeeklyForecastResult[10].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/W0Temp/Unit.text = String(WeeklyForecastResult[10].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/W0Wind/Speed.text = String(WeeklyForecastResult[10].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/W0Wind/Direction.text = String(WeeklyForecastResult[10].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W10/Forecast.text = String(WeeklyForecastResult[10].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/Date.text = String(WeeklyForecastResult[11].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/W0Temp/Temp.text = String(WeeklyForecastResult[11].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/W0Temp/Unit.text = String(WeeklyForecastResult[11].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/W0Wind/Speed.text = String(WeeklyForecastResult[11].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/W0Wind/Direction.text = String(WeeklyForecastResult[11].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W11/Forecast.text = String(WeeklyForecastResult[11].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/Date.text = String(WeeklyForecastResult[12].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/W0Temp/Temp.text = String(WeeklyForecastResult[12].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/W0Temp/Unit.text = String(WeeklyForecastResult[12].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/W0Wind/Speed.text = String(WeeklyForecastResult[12].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/W0Wind/Direction.text = String(WeeklyForecastResult[12].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W12/Forecast.text = String(WeeklyForecastResult[12].detailedForecast)
	
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/Date.text = String(WeeklyForecastResult[13].name)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/W0Temp/Temp.text = String(WeeklyForecastResult[13].temperature)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/W0Temp/Unit.text = String(WeeklyForecastResult[13].temperatureUnit)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/W0Wind/Speed.text = String(WeeklyForecastResult[13].windSpeed)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/W0Wind/Direction.text = String(WeeklyForecastResult[13].windDirection)
	$GUI/Forecasts/Window/WeeklyScroll/WeekCast/W13/Forecast.text = String(WeeklyForecastResult[13].detailedForecast)
