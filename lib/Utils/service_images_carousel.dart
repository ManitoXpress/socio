import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/imagePreview.dart';

class ServiceImagesCarousel extends StatelessWidget {
  final List<String> images;
  const ServiceImagesCarousel({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 500),
        viewportFraction: 0.5,
      ),
      items: images.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewer(imageUrl: url),
                  ),
                );
              },
              child: Hero(
                tag: url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
} 