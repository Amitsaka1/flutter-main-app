import 'gift_model.dart';

/// TOTAL GIFTS
const int totalGifts = 29;

/// AUTO GENERATE GIFTS
final List<GiftModel> giftList = List.generate(

  totalGifts,

  (index) {

    final number = index + 1;

    return GiftModel(
      image: "assets/gifts/$number.png",
      price: number * 10,
    );

  },

);
