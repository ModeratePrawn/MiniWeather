extends Node

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

func _ready():
	print("Program Starting")
	$GUI/AlertDisplay.visible = false
	$GUI/Forecasts.visible = true
	$GUI/Forecasts/Window/NowCast/Alert.visible = false
	findLocation()
	
func findLocation():
	print("Finding Location...")
	$NetworkController/Location.request(GeoAPI)

func _on_Location_request_completed(result, response_code, headers, body):
	print("Location Found.")
	var json = JSON.parse(body.get_string_from_utf8())
	city = json.result.city
	state = json.result.regionName
	stateCode = json.result.region
	zipCode = json.result.zip
	lat = json.result.lat
	long = json.result.lon
	#lat = 33.4025 #For Testing. 
	#long = -84.522 #For Testing
	fullURL = str(baseURL, lat, ",", long)
	CityState = str(city," ",state)
	$GUI/Forecasts/Window/Header/Location.text = String(CityState)
	print("Lat:")
	print(lat)
	print("Long:")
	print(long)
	print("Full URL:")
	print(fullURL)
	print("Fetching Forecast URLs...")
	getGridPoints()

func getGridPoints():
	$NetworkController/Forecast.request(fullURL)

func _on_Forecast_request_completed(result, response_code, headers, body):
	print("Forecast URLs Returned.")
	var GPjson = JSON.parse(body.get_string_from_utf8())
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

func getHourlyForecast():
	$NetworkController/HoulyForecast.request(HForecastURL)

func getWeeklyForecast():
	$NetworkController/WeeklyForecast.request(CatForecastURL)

func getZoneID():
	$NetworkController/ZoneIDRequest.request(ZoneURL)

func _on_HoulyForecast_request_completed(result, response_code, headers, body):
	var HourlyForecastJSON = JSON.parse(body.get_string_from_utf8())
	HourlyForecastResult = HourlyForecastJSON.result.properties.periods
	PrintHourlyResults()

func _on_WeeklyForecast_request_completed(result, response_code, headers, body):
	var WeeklyForecastJSON = JSON.parse(body.get_string_from_utf8())
	WeeklyForecastResult = WeeklyForecastJSON.result.properties.periods
	PrintWeeklyResults()

func _on_ZoneIDRequest_request_completed(result, response_code, headers, body):
	var ZoneIDRequestResult = JSON.parse(body.get_string_from_utf8())
	ZoneID = ZoneIDRequestResult.result.properties.id
	ActiveAlertURL = str(AlertBase,ZoneID)
	print("ZoneID:")
	print(ZoneID)
	print("Active Alerts URL:")
	print(ActiveAlertURL)
	getAlerts()

func getAlerts():
	$NetworkController/AlertRequest.request(ActiveAlertURL)

func _on_AlertRequest_request_completed(result, response_code, headers, body):
	var AlertJSON = JSON.parse(body.get_string_from_utf8())
	Alerts = AlertJSON.result.features
	AlertHandler()

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
		print("Loop:", Counter)
		var NewInstance = scene.instance()
		NewInstance.name = "AlertInfo" + String(Counter)
		path.add_child(NewInstance)
		print("New Instance Name:")
		print(NewInstance.name)
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
	#Hourly Forecast for Next 24 Hours
	$GUI/Forecasts/Window/HourlyScroll/HourlyCast/T0/DateTime.text = String(HourlyForecastResult[1].startTime)
	$GUI/Forecasts/Window/HourlyScroll/HourlyCast/T0/T0Temp/Temp.text = String(HourlyForecastResult[1].temperature)
	$GUI/Forecasts/Window/HourlyScroll/HourlyCast/T0/T0Temp/Unit.text = String(HourlyForecastResult[1].temperatureUnit)
	$GUI/Forecasts/Window/HourlyScroll/HourlyCast/T0/T0Wind/WindSpeed.text = String(HourlyForecastResult[1].windSpeed)
	$GUI/Forecasts/Window/HourlyScroll/HourlyCast/T0/T0Wind/Direction.text = String(HourlyForecastResult[1].windDirection)

func PrintWeeklyResults():
	$GUI/Forecasts/Window/WeeklyScroll.get_v_scrollbar().modulate = Color(0, 0, 0, 0) #Hide Scroll Bar
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
