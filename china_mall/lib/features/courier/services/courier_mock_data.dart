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
      storeLocation: 'Shop 247, Ground Floor',
      storePhone: '+27 11 683 4521',
      pickupCode: pickupCode,
      orderRefs: ['#CM-001', '#CM-002', '#CM-003'],
      items: [
        PickupOrderItem(
          id: 1,
          productName: 'Maxi Wrap Dress',
          quantity: 1,
          sizeOrColor: 'M / Navy',
          orderRef: '#CM-001',
          price: 349.99,
        ),
        PickupOrderItem(
          id: 2,
          productName: 'Cropped Denim Jacket',
          quantity: 1,
          sizeOrColor: 'S / Light Blue',
          orderRef: '#CM-001',
          price: 459.00,
        ),
        PickupOrderItem(
          id: 3,
          productName: 'Block Heel Sandals',
          quantity: 1,
          sizeOrColor: 'Size 6 / Tan',
          orderRef: '#CM-002',
          price: 299.99,
        ),
      ],
    ),
    PickupAssignment(
      id: 2,
      storeName: 'Dragon Fashion',
      storeLocation: 'Shop 112, First Floor',
      storePhone: '+27 11 683 7890',
      pickupCode: pickupCode,
      orderRefs: ['#CM-004', '#CM-005'],
      items: [
        PickupOrderItem(
          id: 4,
          productName: 'Silk Mandarin Collar Shirt',
          quantity: 2,
          sizeOrColor: 'L / Red',
          orderRef: '#CM-004',
          price: 389.00,
        ),
        PickupOrderItem(
          id: 5,
          productName: 'Wide Leg Trousers',
          quantity: 1,
          sizeOrColor: 'M / Black',
          orderRef: '#CM-005',
          price: 279.99,
        ),
      ],
    ),
    PickupAssignment(
      id: 3,
      storeName: 'Plaza Styles',
      storeLocation: 'Shop 89, Ground Floor',
      storePhone: '+27 11 683 2345',
      pickupCode: pickupCode,
      orderRefs: ['#CM-006'],
      items: [
        PickupOrderItem(
          id: 6,
          productName: 'Embroidered Tote Bag',
          quantity: 1,
          sizeOrColor: 'Gold',
          orderRef: '#CM-006',
          price: 199.99,
        ),
        PickupOrderItem(
          id: 7,
          productName: 'Beaded Statement Necklace',
          quantity: 1,
          orderRef: '#CM-006',
          price: 149.00,
        ),
      ],
    ),
  ];

  static List<DeliveryTask> get deliveryTasks => [
    DeliveryTask(
      id: 1,
      customerName: 'Thabo M.',
      deliveryAddress: '42 Hawley Road, Bedfordview, 2007',
      customerPhone: '+27 72 345 6789',
      orderRef: '#CM-001',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(
          productName: 'Maxi Wrap Dress',
          quantity: 1,
          storeName: 'Fashion Hub',
        ),
        const DeliveryItem(
          productName: 'Cropped Denim Jacket',
          quantity: 1,
          storeName: 'Fashion Hub',
        ),
      ],
    ),
    DeliveryTask(
      id: 2,
      customerName: 'Naledi K.',
      deliveryAddress: '18 Immink Drive, Diepkloof, Soweto, 1864',
      customerPhone: '+27 83 456 7890',
      orderRef: '#CM-004',
      deliveryCode: deliveryCode,
      items: [
        const DeliveryItem(
          productName: 'Silk Mandarin Collar Shirt',
          quantity: 2,
          storeName: 'Dragon Fashion',
        ),
      ],
    ),
    DeliveryTask(
      id: 3,
      customerName: 'Sipho D.',
      deliveryAddress: '7 Rivonia Boulevard, Sandton, 2196',
      customerPhone: '+27 61 567 8901',
      orderRef: '#CM-006',
      deliveryCode: deliveryCode,
      status: DeliveryStatus.arriving,
      items: [
        const DeliveryItem(
          productName: 'Embroidered Tote Bag',
          quantity: 1,
          storeName: 'Plaza Styles',
        ),
        const DeliveryItem(
          productName: 'Beaded Statement Necklace',
          quantity: 1,
          storeName: 'Plaza Styles',
        ),
      ],
    ),
  ];

  static List<DeliveryHistoryEntry> get deliveryHistory => [
    DeliveryHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      batchWindow: '9:00 AM',
      storeName: 'Fashion Hub',
      deliveriesCompleted: 4,
      earnings: 380.00,
    ),
    DeliveryHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      batchWindow: '3:00 PM',
      storeName: 'Dragon Fashion',
      deliveriesCompleted: 3,
      earnings: 285.00,
    ),
    DeliveryHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      batchWindow: '9:00 AM',
      storeName: 'Plaza Styles',
      deliveriesCompleted: 5,
      earnings: 475.00,
    ),
    DeliveryHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 3)),
      batchWindow: '3:00 PM',
      storeName: 'Fashion Hub',
      deliveriesCompleted: 2,
      earnings: 190.00,
    ),
    DeliveryHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 4)),
      batchWindow: '9:00 AM',
      storeName: 'Dragon Fashion',
      deliveriesCompleted: 6,
      earnings: 570.00,
    ),
  ];
}
