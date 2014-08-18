


app = angular.module("oauthd", ["ui.router"]).config(["$stateProvider", "$urlRouterProvider", "$locationProvider",
	($stateProvider, $urlRouterProvider, $locationProvider) ->
		

		$stateProvider.state 'login',
			url: '/login',
			templateUrl: '/templates/login.html'
			controller: 'LoginCtrl'

		$stateProvider.state 'dashboard',
			url: '/',
			templateUrl: '/templates/dashboard.html'
			controller: 'DashboardCtrl'

		$stateProvider.state 'dashboard.apps',
			url: 'apps',
			templateUrl: '/templates/apps.html'
			controller: 'AppsCtrl'

		$stateProvider.state 'dashboard.apps.show',
			url: '/:id',
			templateUrl: '/templates/app-show.html'
			controller: 'AppShowCtrl'

		$urlRouterProvider.otherwise '/login' 

		$locationProvider.html5Mode(true)
])

require('./filters/filters') app

require('./services/UserService') app

require('./controllers/DashboardCtrl') app
require('./controllers/LoginCtrl') app
require('./controllers/AppsCtrl') app
require('./controllers/Apps/AppShowCtrl') app

app.run(["$rootScope", "UserService",
	($rootScope, UserService) ->
		window.scope = $rootScope
		$rootScope.loading = true
		$rootScope.logged_user = amplify.store('user')
		$rootScope.accessToken = amplify.store('accessToken')

		$rootScope.$watch 'logged_user', () ->
			if ($rootScope.logged_user?)
				amplify.store('user', $rootScope.logged_user)
			else
				amplify.store('user', null)

		$rootScope.$watch 'accessToken', () ->
			if ($rootScope.accessToken?)
				amplify.store('accessToken', $rootScope.accessToken)
			else
				amplify.store('accessToken', null)
		
		$rootScope.logout = () ->
			UserService.logout()

])