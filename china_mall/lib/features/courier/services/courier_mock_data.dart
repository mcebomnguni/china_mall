import '../models/pickup_assignment.dart';
import '../models/delivery_task.dart';
import '../models/batch_schedule.dart';

class CourierMockData {
  // Verification codes
  static const pickupCode = '482917';
  static const deliveryCode = '731564';

  static BatchSchedule get currentBatch => BatchSchedule.current();

  // Stats
  static const int pickupsToday = 4;
  static const int deliveriesToday = 3;
  static const double earningsToday = 285.00;

  static List<PickupAssignment> get pickupAssignments => [
    PickupAssignment(
      id: 1,
      storeName: 'Fashion Hub',
      storeLocation: 'Shop 247, Ground Floor \u2014 Oriental Plaza, Fordsburg',
      storePhone: '+27 11 838 6731',
      pickupCode: pickupCode,
      orderRefs: ['#CS-001', '#CS-002'],
      items: [
        PickupOrderItem(
          id: 1,
          productName: 'Premium Faux Leather Jacket',
          quantity: 1,
          sizeOrColor: 'L / Black',
          orderRef: '#CS-001',
          price: 349.00,
        ),
        PickupOrderItem(
          id: 2,
          productName: 'White Sneakers',
          quantity: 1,
          sizeOrColor: 'Size 42 / White',
          orderRef: '#CS-001',
          price: 249.00,
        ),
        PickupOrderItem(
          id: 3,
          productName: 'Floral Maxi Dress',
          quantity: 1,
          sizeOrColor: 'M / Red',
          orderRef: '#CS-002',
          price: 199.00,
        ),
      ],
    ),
    PickupAssignment(
      id: 2,
      storeName: 'Dragon Fashion',
      storeLocation: 'Shop 112, First Floor \u2014 China Mall, Crown Mines',
      storePhone: '+27 11 837 4422',
      pickupCode: pickupCode,
      orderRefs: ['#CS-003'],
      items: [
        PickupOrderItem(
          id: 4,
          productName: 'Red Hoodie',
          quantity: 2,
          sizeOrColor: 'XL / Red',
          orderRef: '#CS-003',
          price: 189.00,
        ),
        PickupOrderItem(
          id: 5,
          productName: 'Denim Jeans',
          quantity: 1,
          sizeOrColor: 'Size 34 / Blue',
          orderRef: '#CS-003',
          price: 219.00,
        ),
      ],
    ),
    PickupAssignment(
      id: 3,
      storeName: 'Plaza Styles',
      storeLocation: 'Shop 56, Ground Floor \u2014 China Mall, Crown Mines',
      storePhone: '+27 11 839 1100',
      pickupCode: pickupCode,
      orderRefs: ['#CS-004'],
      items: [
        PickupOrderItem(
          id: 6,
          productName: 'Gold Hoop Earrings',
          quantity: 1,
          sizeOrColor: 'Gold',
          orderRef: '#CS-004',
          price: 89.00,
        ),
        PickupOrderItem(
          id: 7,
          productName: 'Black Handbag',
          quantity: 1,
          sizeOrColor: 'Black',
          orderRef: '#CS-004',
          price: 199.00,
        ),
      ],
    ),
  ];

  static List<DeliveryTask> get deliveryTasks => [
    DeliveryTask(
      id: 1,
      customerFirstName: 'Thabo',
      customerLastName: 'Mokoena',
      suburb: 'Bedfordview',
      fullAddress: '16 Dagbreek Street, Bedfordview, 2008',
      customerPhone: '+27 72 345 6789',
      orderRef: '#CS-001',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(productName: 'Premium Faux Leather Jacket', quantity: 1, storeName: 'Fashion Hub', size: 'L'),
        const DeliveryItem(productName: 'White Sneakers', quantity: 1, storeName: 'Fashion Hub', size: '42'),
      ],
    ),
    DeliveryTask(
      id: 2,
      customerFirstName: 'Lerato',
      customerLastName: 'Khumalo',
      suburb: 'Soweto, Diepkloof',
      fullAddress: '42 Immink Drive, Diepkloof Zone 6, Soweto, 1862',
      customerPhone: '+27 73 456 7890',
      orderRef: '#CS-002',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(productName: 'Floral Maxi Dress', quantity: 1, storeName: 'Fashion Hub', size: 'M'),
      ],
    ),
    DeliveryTask(
      id: 3,
      customerFirstName: 'Sipho',
      customerLastName: 'Nkosi',
      suburb: 'Sandton',
      fullAddress: '8 Rivonia Road, Sandton, 2196',
      customerPhone: '+27 74 567 8901',
      orderRef: '#CS-003',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(productName: 'Red Hoodie', quantity: 2, storeName: 'Dragon Fashion', size: 'XL'),
        const DeliveryItem(productName: 'Denim Jeans', quantity: 1, storeName: 'Dragon Fashion', size: '34'),
      ],
    ),
    DeliveryTask(
      id: 4,
      customerFirstName: 'Nomsa',
      customerLastName: 'Dlamini',
      suburb: 'Boksburg',
      fullAddress: '23 Tri Street, Boksburg North, 1459',
      customerPhone: '+27 76 678 9012',
      orderRef: '#CS-004',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(productName: 'Gold Hoop Earrings', quantity: 1, storeName: 'Plaza Styles'),
        const DeliveryItem(productName: 'Black Handbag', quantity: 1, storeName: 'Plaza Styles'),
      ],
    ),
  ];

  static List<DeliveryHistoryEntry> get deliveryHistory => [
    DeliveryHistoryEntry(
      date: DateTime(2026, 4, 2),
      batchWindow: '9:00 AM',
      stores: ['Fashion Hub', 'Dragon Fashion'],
      deliveriesCompleted: 4,
      earnings: 240,
    ),
    DeliveryHistoryEntry(
      date: DateTime(2026, 4, 2),
      batchWindow: '3:00 PM',
      stores: ['Plaza Styles', 'Urban Edge'],
      deliveriesCompleted: 3,
      earnings: 180,
    ),
    DeliveryHistoryEntry(
      date: DateTime(2026, 4, 1),
      batchWindow: '9:00 AM',
      stores: ['Fashion Hub', 'Classic Threads', 'Dragon Fashion'],
      deliveriesCompleted: 5,
      earnings: 300,
    ),
    DeliveryHistoryEntry(
      date: DateTime(2026, 4, 1),
      batchWindow: '3:00 PM',
      stores: ['Street Wear Co'],
      deliveriesCompleted: 2,
      earnings: 120,
    ),
    DeliveryHistoryEntry(
      date: DateTime(2026, 3, 31),
      batchWindow: '9:00 AM',
      stores: ['Fashion Hub', 'Plaza Styles'],
      deliveriesCompleted: 4,
      earnings: 240,
    ),
  ];

  static final CourierEarnings earnings = CourierEarnings(
    thisWeek: 540,
    deliveriesThisWeek: 12,
    nextPayoutDate: DateTime(2026, 4, 4),
    estimatedPayout: 540,
    bankName: 'FNB',
    bankAccountLast4: '4521',
    payoutHistory: [
      PayoutEntry(period: '24-30 Mar', amount: 1080, status: PayoutStatus.paid),
      PayoutEntry(period: '17-23 Mar', amount: 960, status: PayoutStatus.paid),
      PayoutEntry(period: '10-16 Mar', amount: 1200, status: PayoutStatus.paid),
    ],
  );
}
