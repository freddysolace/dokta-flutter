import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/geolocator_service.dart';
import '../services/marker_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';

class Search extends StatelessWidget {
  const Search({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentPosition = Provider.of<Position>(context);
    final placesProvider = Provider.of<Future<List<Place>>>(context);
    final geoService = GeoLocatorService();
    final markerService = MarkerService();

    return FutureProvider(
      create: (context) => placesProvider,
      child: Scaffold(
        body: (currentPosition != null)
            ? Consumer<List<Place>>(
                builder: (_, places, __) {
                  var markers = (places != null)
                      ? markerService.getMarkers(places)
                      : <Marker>[];
                  return (places != null)
                      ? Column(
                          children: <Widget>[
                            Container(
                              height: MediaQuery.of(context).size.height / 3,
                              width: MediaQuery.of(context).size.width,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                    target: LatLng(currentPosition.latitude,
                                        currentPosition.longitude),
                                    zoom: 16.0),
                                zoomGesturesEnabled: true,
                                markers: Set<Marker>.of(markers),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Expanded(
                              child: ListView.builder(
                                  itemCount: places.length,
                                  itemBuilder: (context, index) {
                                    return FutureProvider(
                                      create: (context) =>
                                          geoService.getDistance(
                                              currentPosition.latitude,
                                              currentPosition.longitude,
                                              places[index]
                                                  .geometry
                                                  .location
                                                  .lat,
                                              places[index]
                                                  .geometry
                                                  .location
                                                  .lng),
                                      child: Card(
                                        child: ListTile(
                                          title: Text(places[index].name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const SizedBox(
                                                height: 3.0,
                                              ),
                                              (places[index].rating != null)
                                                  ? Row(
                                                      children: <Widget>[
                                                        RatingBarIndicator(
                                                          rating: places[index]
                                                              .rating,
                                                          itemBuilder: (context,
                                                                  index) =>
                                                              const Icon(
                                                                  Icons.star,
                                                                  color: Colors
                                                                      .amber),
                                                          itemCount: 5,
                                                          itemSize: 10.0,
                                                          direction:
                                                              Axis.horizontal,
                                                        )
                                                      ],
                                                    )
                                                  : Row(),
                                              const SizedBox(
                                                height: 5.0,
                                              ),
                                              Consumer<double>(
                                                builder:
                                                    (context, meters, wiget) {
                                                  return (meters != null)
                                                      ? Text(
                                                          '${places[index].vicinity} \u00b7 ${(meters / 1000).toStringAsFixed(1)} km')
                                                      : Container();
                                                },
                                              )
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.directions),
                                            color:
                                                Theme.of(context).primaryColor,
                                            onPressed: () {
                                              _launchMapsUrl(
                                                  places[index]
                                                      .geometry
                                                      .location
                                                      .lat,
                                                  places[index]
                                                      .geometry
                                                      .location
                                                      .lng);
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            )
                          ],
                        )
                      : const Center(child: CircularProgressIndicator());
                },
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Future<void> _launchMapsUrl(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }
}
