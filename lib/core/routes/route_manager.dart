import 'package:flutter/material.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_jcb_stock_screen.dart';
import '../../screens/admin/admin_order_and_renting_details_screen.dart';
import '../../screens/admin/admin_profile_screen.dart';
import '../../screens/admin/admin_stocks_screen.dart';
import '../../screens/admin/admin_tipper_stock_screen.dart';
import '../../screens/admin/admin_tractor_stock_screen.dart';
import '../../screens/admin/admin_vehicle_rent_screen.dart';
import '../../screens/admin/driver_details_screen.dart';
import '../../screens/admin/drivers_screen.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/driver_profile_screen.dart';
import '../../screens/driver/driver_today_jobs_screen.dart';
import '../../screens/driver/my_orders_or_rentings_screen.dart';
import '../../screens/driver/my_status_screen.dart';
import '../../screens/customer/cart_screen.dart';
import '../../screens/customer/home_screen.dart';
import '../../screens/customer/jcb_stock_screen.dart';
import '../../screens/auth/logo_screen.dart';
import '../../screens/customer/order_screen.dart';
import '../../screens/customer/order_and_renting_details_screen.dart';
import '../../screens/customer/profile_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/signin_screen.dart';
import '../../screens/customer/stocks_screen.dart';
import '../../screens/customer/tipper_stock_screen.dart';
import '../../screens/customer/tractor_stock_screen.dart';
import '../../screens/customer/vehicle_rent_screen.dart';
import '../theme/page_transitions.dart';

class RouteManager {
  static const String logo = '/';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String profile = '/profile';
  static const String train = '/train';
  static const String home = '/home';
  static const String stocks = '/stocks';
  static const String vehicleRent = '/vehicleRent';
  static const String tractorStock = '/tractorStock';
  static const String jcbStock = '/jcbStock';
  static const String tipperStock = '/tipperStock';
  static const String cart = '/cart';
  static const String order = '/order';
  static const String orderAndRentingDetails = '/orderAndRentingDetails';
  static const String adminHome = '/adminHome';
  static const String adminProfile = '/adminProfile';
  static const String adminStocks = '/adminStocks';
  static const String adminVehicleRent = '/adminVehicleRent';
  static const String adminJcbStock = '/adminJcbStock';
  static const String adminTractorStock = '/adminTractorStock';
  static const String adminTipperStock = '/adminTipperStock';
  static const String adminOrderAndRentingDetails = '/adminOrderAndRentingDetails';
  static const String drivers = '/drivers';
  static const String driverDetails = '/driverDetails';
  static const String driverHome = '/driverHome';
  static const String driverProfile = '/driverProfile';
  static const String myOrdersOrRentings = '/myOrdersOrRentings';
  static const String myStatus = '/myStatus';
  static const String driverTodayJobs = '/driverTodayJobs';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case logo:
        return FadeScalePageRoute(page: const Logo(), settings: settings);

      case signup:
        return SlidePageRoute(page: const SignUp(), settings: settings);

      case signin:
        return FadeScalePageRoute(page: const Login(), settings: settings);

      case home:
        return FadeScalePageRoute(page: const Home(), settings: settings);

      case stocks:
        return SlidePageRoute(page: const Stocks(), settings: settings);

      case vehicleRent:
        return SlidePageRoute(page: const VehicleRent(), settings: settings);

      case tractorStock:
        return SlidePageRoute(page: const TractorStock(), settings: settings);

      case jcbStock:
        return SlidePageRoute(page: const JcbStock(), settings: settings);

      case tipperStock:
        return SlidePageRoute(page: const TipperStock(), settings: settings);

      case cart:
        return SlidePageRoute(page: const Cart(), settings: settings);

      case order:
        return SlidePageRoute(page: const Order(), settings: settings);

      case profile:
        return SlidePageRoute(page: const Profile(), settings: settings);

      case orderAndRentingDetails:
        return SlidePageRoute(page: const OrderAndRentingDetails(), settings: settings);

      case adminHome:
        return FadeScalePageRoute(page: const AdminHome(), settings: settings);

      case adminStocks:
        return SlidePageRoute(page: const AdminStocks(), settings: settings);

      case adminVehicleRent:
        return SlidePageRoute(page: const AdminVehicleRent(), settings: settings);

      case adminJcbStock:
        return SlidePageRoute(page: const AdminJcbStock(), settings: settings);

      case adminTractorStock:
        return SlidePageRoute(page: const AdminTractorStock(), settings: settings);

      case adminTipperStock:
        return SlidePageRoute(page: const AdminTipperStock(), settings: settings);

      case adminOrderAndRentingDetails:
        return SlidePageRoute(page: const AdminOrderAndRentingDetails(), settings: settings);

      case adminProfile:
        return SlidePageRoute(page: const AdminProfile(), settings: settings);

      case drivers:
        return SlidePageRoute(page: const Drivers(), settings: settings);

      case driverDetails:
        final driverId = settings.arguments is String ? settings.arguments as String : '';
        return SlidePageRoute(page: DriverDetails(driverId: driverId), settings: settings);

      case driverHome:
        return FadeScalePageRoute(page: const DriverHome(), settings: settings);

      case driverProfile:
        return SlidePageRoute(page: const DriverProfile(), settings: settings);

      case myOrdersOrRentings:
        return SlidePageRoute(page: const MyOrdersOrRentings(), settings: settings);

      case myStatus:
        return SlidePageRoute(page: const MyStatus(), settings: settings);

      case driverTodayJobs:
        return SlidePageRoute(page: DriverTodayJobs(), settings: settings);

      default:
        throw FormatException("No Route found for ${settings.name}");
    }
  }
}