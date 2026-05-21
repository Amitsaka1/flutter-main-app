import 'package:flutter/material.dart';

import '../../data/gift_list.dart';

class GiftPanel extends StatelessWidget {

  const GiftPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    // ================= UI START =================

    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),

        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      child: GridView.builder(

        itemCount: giftList.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),

        itemBuilder:
            (context, index) {

          final gift =
              giftList[index];

          return Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              Container(
                width: 40,
                height: 40,

                padding:
                    const EdgeInsets.all(4),

                decoration: BoxDecoration(
                  color:
                      Colors.grey.shade800,

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Image.asset(
                  gift.image,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "${gift.price}",

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );

    // ================= UI END =================
  }
}
