# Author Marek Pietrucha
# https://github.com/mareczek/international-phone-number

"use strict"
angular.module("internationalPhoneNumber", [])

.constant 'ipnConfig', {
    allowExtensions:        false
    autoFormat:             true
    autoHideDialCode:       true
    autoPlaceholder:        true
    customPlaceholder:      null
    defaultCountry:         ""
    geoIpLookup:            null
    nationalMode:           true
    numberType:             "MOBILE"
    onlyCountries:          undefined
    preferredCountries:     ['us', 'gb']
    skipUtilScriptDownload: false
    utilsScript:            ""
  }

.directive 'internationalPhoneNumber', ['$timeout', 'ipnConfig', ($timeout, ipnConfig) ->

  restrict:   'A'
  require: '^ngModel'
  scope:
    ngModel: '='
    country: '='

  link: (scope, element, attrs, ctrl) ->

    if ctrl
      if element.val() != ''
        $timeout () ->
          element.intlTelInput 'setNumber', element.val()
          ctrl.$setViewValue element.val()
        , 0


    read = () ->
      ctrl.$setViewValue element.val()

    handleWhatsSupposedToBeAnArray = (value) ->
      if value instanceof Array
        value
      else
        value.toString().replace(/[ ]/g, '').split(',')

    options = angular.copy(ipnConfig)

    angular.forEach options, (value, key) ->
      return unless attrs.hasOwnProperty(key) and angular.isDefined(attrs[key])
      option = attrs[key]
      if key == 'preferredCountries'
        options.preferredCountries = handleWhatsSupposedToBeAnArray option
      else if key == 'onlyCountries'
        options.onlyCountries = handleWhatsSupposedToBeAnArray option
      else if typeof(value) == "boolean"
        options[key] = (option == "true")
      else
        options[key] = option

    changeCountry = (country) ->
      if country != null && country != undefined && country != ''
        if options.onlyCountries && options.onlyCountries.indexOf(country.toLowerCase()) == -1
          return

        element.intlTelInput("selectCountry", country)

    # Wait for ngModel to be set
    watchOnce = scope.$watch('ngModel', (newValue) ->
      # Wait to see if other scope variables were set at the same time
      scope.$$postDigest ->

        if newValue != null && newValue != undefined && newValue.length > 0

          if newValue[0] != '+'
            newValue = '+' + newValue

          ctrl.$modelValue = newValue

        element.intlTelInput(options)

        unless options.skipUtilScriptDownload || attrs.skipUtilScriptDownload != undefined || options.utilsScript
          element.intlTelInput('loadUtils', '/bower_components/intl-tel-input/lib/libphonenumber/build/utils.js')

        if newValue == null || newValue == undefined
          changeCountry scope.country

        watchOnce()

    )

    scope.$watch('country', changeCountry)

    ctrl.$formatters.push (value) ->
      if !value
        return value

      element.intlTelInput 'setNumber', value
      value

    ctrl.$parsers.push (value) ->
      value = element.intlTelInput 'getNumber'

      if !value
        return value

      selectedCountryData = element.intlTelInput "getSelectedCountryData"
      prefixLength = selectedCountryData.dialCode.length + 1

      value.substring(0, prefixLength) + ' ' + value.substring(prefixLength)

    ctrl.$validators.internationalPhoneNumber = (value) ->
      selectedCountry = element.intlTelInput('getSelectedCountryData')

      if !value || (selectedCountry && selectedCountry.dialCode == value)
        return true

      element.intlTelInput("isValidNumber")

    element.on 'blur keyup change', (event) ->
      $timeout () -> read()

    element.on '$destroy', () ->
      element.intlTelInput('destroy');
      element.off 'blur keyup change'
]
