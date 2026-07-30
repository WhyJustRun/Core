/*jslint browser: true, indent: 2, nomen: true*/
/*global google*/

window.WJR = window.WJR || {};
WJR.map = (function ($, _) {
  'use strict';
  var map = {}, googleMapsPromise = null, loadGoogleMaps;

  // Loads the Google Maps API on first use. The API key is provided by the
  // page via a meta tag, and the returned promise resolves once the API's
  // callback= parameter fires.
  loadGoogleMaps = function () {
    if (googleMapsPromise === null) {
      googleMapsPromise = new Promise(function (resolve) {
        var key = document.querySelector('meta[name="wjr.google-maps-key"]').content,
          script = document.createElement('script');
        window.wjrGoogleMapsLoaded = resolve;
        script.src = 'https://maps.googleapis.com/maps/api/js?key=' + encodeURIComponent(key) + '&callback=wjrGoogleMapsLoaded';
        document.head.appendChild(script);
      });
    }
    return googleMapsPromise;
  };

  map.SimpleMarkerMap = function () {
    this.initialize = function (element) {
      loadGoogleMaps().then(function () {
        var lat, lng, zoom, mobileUrl, modalEvents,
          mapOptions, marker, center, googleMap, clickHandler, useMobileUrl;
        lat = +(element.getAttribute('data-lat'));
        lng = +(element.getAttribute('data-lng'));
        zoom = +(element.getAttribute('data-zoom'));
        mobileUrl = element.getAttribute('data-mobile-url');
        useMobileUrl = ($(window).width() < 768) && mobileUrl !== null;
        center = new google.maps.LatLng(lat, lng);
        mapOptions = {
          zoom: zoom,
          center: center,
          scrollwheel: false,
          draggable: !useMobileUrl,
          disableDefaultUI: useMobileUrl,
          mapTypeId: google.maps.MapTypeId.HYBRID
        };

        googleMap = new google.maps.Map(element, mapOptions);

        marker = new google.maps.Marker({
          position: center
        });
        marker.setMap(googleMap);

        if (useMobileUrl) {
          modalEvents = ['click'];
          clickHandler = function () {
            window.location = mobileUrl;
          };

          _.each(modalEvents, function (modalEvent) {
            google.maps.event.addListener(googleMap, modalEvent, clickHandler);
          });
        }
      });
    };
  };

  map.DraggableMarkerMap = function () {
    this.initialize = function (element) {
      loadGoogleMaps().then(function () {
        var latElement, lngElement, zoom, googleMap, options, center, marker, updateUrl;
        latElement = $(element.getAttribute('data-lat-element'));
        lngElement = $(element.getAttribute('data-lng-element'));
        zoom = +(element.getAttribute('data-zoom'));
        updateUrl = element.getAttribute('data-update-url');

        center = new google.maps.LatLng(latElement.val(), lngElement.val());
        options = {
          center: center,
          zoom: zoom,
          mapTypeId: google.maps.MapTypeId.HYBRID
        };
        googleMap = new google.maps.Map(element, options);

        marker = new google.maps.Marker({
          position: center,
          draggable: true
        });

        google.maps.event.addListener(marker, 'dragend', function () {
          var position = marker.getPosition();
          latElement.val(position.lat());
          lngElement.val(position.lng());
          if (updateUrl) {
            // Persist immediately; the CSRF header comes from the global
            // $.ajaxSetup in wjr/wjr.js.
            $.post(updateUrl + '/' + position.lat() + '/' + position.lng());
          }
        });

        marker.setMap(googleMap);
      });
    };
  };

  map.MultiMarkerMap = function () {
    this.initialize = function (element) {
      loadGoogleMaps().then(function () {
        var lat, fetchUrl, fetchEntity, fetchMarkers, fetchMarkerImages, fetchBounds,
          lng, zoom, googleMap, markerClusterer, options, center, markers, fetchInProgress;
        lat = +(element.getAttribute('data-lat'));
        lng = +(element.getAttribute('data-lng'));
        zoom = +(element.getAttribute('data-zoom'));
        fetchUrl = element.getAttribute('data-fetch-url');
        fetchEntity = element.getAttribute('data-fetch-entity');
        fetchMarkerImages = element.getAttribute('data-fetch-markerimages');
        center = new google.maps.LatLng(lat, lng);
        options = {
          center: center,
          zoom: zoom,
          mapTypeId: google.maps.MapTypeId.HYBRID
        };

        googleMap = new google.maps.Map(element, options);
        markers = {};
        markerClusterer = new MarkerClusterer(googleMap, markers,
            {imagePath: fetchMarkerImages, maxZoom: 11});

        fetchInProgress = false;
        fetchBounds = null;
        fetchMarkers = function () {
          if (!fetchInProgress) {
            fetchInProgress = true;
            var bounds, ne, sw, url;
            bounds = googleMap.getBounds();
            fetchBounds = bounds;
            ne = bounds.getNorthEast();
            sw = bounds.getSouthWest();
            url = fetchUrl;
            url += '?max_lat=' + ne.lat() + '&min_lat=' + sw.lat();
            url += '&max_lng=' + ne.lng() + '&min_lng=' + sw.lng();
            $.ajax({
              url: url,
              success: function (data) {
                _.each(data[fetchEntity], function (entity) {
                  if (_.has(markers, entity.id)) {
                    return;
                  }
                  var marker, color, infoWindow;
                  infoWindow = new google.maps.InfoWindow({
                    content: '<a href="' + entity.url +
                             '"><h3>' + entity.name + '</h3></a>'
                  });
                  color = (entity.map_standard && entity.map_standard.color) ? entity.map_standard.color : 'rgba(0,0,0,1)';
                  marker = new google.maps.Marker({
                    position: new google.maps.LatLng(entity.lat, entity.lng),
                    icon: {
                        path: "M12,11.5A2.5,2.5 0 0,1 9.5,9A2.5,2.5 0 0,1 12,6.5A2.5,2.5 0 0,1 14.5,9A2.5,2.5 0 0,1 12,11.5M12,2A7,7 0 0,0 5,9C5,14.25 12,22 12,22C12,22 19,14.25 19,9A7,7 0 0,0 12,2Z",
                        fillColor: color,
                        fillOpacity: 1.0,
                        anchor: new google.maps.Point(12, 24),
                        strokeOpacity: 0.5,
                        strokeWeight: 2.0,
                        strokeColor: '#000000',
                        scale: 2.0
                   },
                  });
                  google.maps.event.addListener(marker, 'click', function () {
                    infoWindow.open(googleMap, marker);
                  });
                  markerClusterer.addMarker(marker);
                  markers[entity.id] = marker;
                });
              },
              complete: function () {
                fetchInProgress = false;
                // If the bounds have changed since the last fetch, start another fetch
                if (!fetchBounds.equals(googleMap.getBounds())) {
                  fetchMarkers();
                }
              }
            });
          }
        };

        google.maps.event.addListener(googleMap, 'bounds_changed', fetchMarkers);
      });
    };
  };

  return map;
}(jQuery, _));
