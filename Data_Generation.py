import csv
import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()

# Set random seed for reproducibility
random.seed(42)

# Indian cities for Zomato data
INDIAN_CITIES = [
    "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Ahmedabad",
    "Chennai", "Kolkata", "Surat", "Pune", "Jaipur",
    "Lucknow", "Kanpur", "Nagpur", "Indore", "Thane",
    "Bhopal", "Visakhapatnam", "Patna", "Vadodara", "Ghaziabad"
]

# Restaurant types and names
RESTAURANT_TYPES = [
    "Cafe", "Restaurant", "Dhaba", "Bistro", "Eatery",
    "Kitchen", "Grill", "Pizzeria", "Bakery", "Diner"
]

CUISINES = [
    "North Indian", "South Indian", "Chinese", "Italian", "Mexican",
    "Continental", "Fast Food", "Desserts", "Beverages", "Street Food"
]

RESTAURANT_PREFIXES = [
    "Spice", "Royal", "Taste", "Food", "Delight",
    "Hungry", "Chef", "Kitchen", "Flavor", "Zesty"
]

RESTAURANT_SUFFIXES = [
    "Hub", "Point", "Corner", "Palace", "Express",
    "Zone", "Spot", "House", "Inn", "Bites"
]

# Food items with prices
FOOD_ITEMS = {
    "North Indian": [
        ("Butter Chicken", 350), ("Paneer Tikka", 280), ("Dal Makhani", 220),
        ("Naan", 60), ("Biryani", 320), ("Tandoori Roti", 25),
        ("Palak Paneer", 260), ("Chole Bhature", 180), ("Samosa", 40),
        ("Rajma Chawal", 200)
    ],
    "South Indian": [
        ("Dosa", 120), ("Idli", 80), ("Vada", 70), ("Uttapam", 140),
        ("Sambhar", 90), ("Rasam", 80), ("Bisi Bele Bath", 180),
        ("Pongal", 100), ("Medu Vada", 70), ("Masala Dosa", 150)
    ],
    "Chinese": [
        ("Hakka Noodles", 180), ("Manchurian", 200), ("Spring Rolls", 160),
        ("Fried Rice", 190), ("Chilli Chicken", 220), ("Dim Sum", 170),
        ("Schezwan Noodles", 200), ("Hot & Sour Soup", 150),
        ("Gobi Manchurian", 180), ("American Chopsuey", 210)
    ],
    "Italian": [
        ("Margherita Pizza", 300), ("Pasta Alfredo", 280), ("Lasagna", 320),
        ("Garlic Bread", 120), ("Risotto", 250), ("Bruschetta", 160),
        ("Tiramisu", 200), ("Fettuccine", 270), ("Calzone", 290),
        ("Caprese Salad", 180)
    ],
    "Mexican": [
        ("Tacos", 220), ("Burrito", 250), ("Quesadilla", 210),
        ("Nachos", 190), ("Guacamole", 160), ("Enchiladas", 270),
        ("Fajitas", 280), ("Salsa", 100), ("Churros", 150),
        ("Mexican Rice", 180)
    ]
}

ORDER_STATUSES = ["Pending", "Confirmed", "Preparing", "Ready for Pickup", "Completed", "Cancelled"]
DELIVERY_STATUSES = ["Assigned", "Picked Up", "In Transit", "Delivered", "Failed"]

def generate_customers_data(num_records=200):
    """Generate customers data"""
    customers = []
    current_date = datetime.now()
    
    for i in range(1, num_records + 1):
        customer_id = i
        customer_name = fake.name()
        # Registration dates from 1 year to 1 month ago
        reg_date = fake.date_between(
            start_date=current_date - timedelta(days=365),
            end_date=current_date - timedelta(days=30)
        )
        customers.append([customer_id, customer_name, reg_date])
    
    with open('zomato_customers.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['customer_id', 'customer_name', 'reg_date'])
        writer.writerows(customers)
    
    print(f"Generated customers data: {len(customers)} records")
    return customers

def generate_restaurants_data(num_records=200):
    """Generate restaurants data"""
    restaurants = []
    
    for i in range(1, num_records + 1):
        restaurant_id = i
        restaurant_name = f"{random.choice(RESTAURANT_PREFIXES)} {random.choice(RESTAURANT_SUFFIXES)} {random.choice(RESTAURANT_TYPES)}"
        city = random.choice(INDIAN_CITIES)
        cuisine = random.choice(CUISINES)
        restaurant_name = f"{restaurant_name} - {cuisine}"
        
        # Opening times between 7 AM and 12 PM
        opening_hour = random.randint(7, 12)
        opening_time = f"{opening_hour:02d}:00:00"
        
        # Closing times between 10 PM and 2 AM next day
        closing_hour = random.randint(22, 26)  # 22-26 represents 10 PM to 2 AM
        if closing_hour >= 24:
            closing_hour -= 24
        closing_time = f"{closing_hour:02d}:00:00"
        
        # Total opening hours (8-16 hours)
        total_opening_hours = random.randint(8, 16)
        
        restaurants.append([restaurant_id, restaurant_name, city, opening_time, closing_time, total_opening_hours])
    
    with open('zomato_restaurants.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['restaurant_id', 'restaurant_name', 'city', 'opening_time', 'closing_time', 'total_opening_hours'])
        writer.writerows(restaurants)
    
    print(f"Generated restaurants data: {len(restaurants)} records")
    return restaurants

def generate_riders_data(num_records=200):
    """Generate riders data"""
    riders = []
    current_date = datetime.now()
    
    for i in range(1, num_records + 1):
        rider_id = i
        rider_name = fake.name()
        # Signup dates from 2 years to 1 month ago
        signup_date = fake.date_between(
            start_date=current_date - timedelta(days=730),
            end_date=current_date - timedelta(days=30)
        )
        riders.append([rider_id, rider_name, signup_date])
    
    with open('zomato_riders.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['rider_id', 'rider_name', 'signup_date'])
        writer.writerows(riders)
    
    print(f"Generated riders data: {len(riders)} records")
    return riders

def generate_orders_data(customers, restaurants, num_records=20000):
    """Generate orders data with realistic patterns"""
    orders = []
    current_date = datetime.now()
    
    # Create date range for orders (last 1 year)
    end_date = current_date
    start_date = current_date - timedelta(days=365)
    
    for i in range(1, num_records + 1):
        order_id = i
        customer = random.choice(customers)
        customer_id = customer[0]
        
        restaurant = random.choice(restaurants)
        restaurant_id = restaurant[0]
        restaurant_name = restaurant[1]
        
        # Determine cuisine from restaurant name
        cuisine = None
        for c in CUISINES:
            if c in restaurant_name:
                cuisine = c
                break
        if cuisine is None:
            cuisine = random.choice(CUISINES)
        
        # Generate order items
        num_items = random.randint(1, 5)
        order_items = []
        total_amount = 0
        
        for _ in range(num_items):
            if cuisine in FOOD_ITEMS:
                item, price = random.choice(FOOD_ITEMS[cuisine])
            else:
                item = f"{random.choice(['Special', 'Deluxe', 'Classic'])} {random.choice(['Dish', 'Meal', 'Platter'])}"
                price = random.randint(150, 500)
            
            quantity = random.randint(1, 3)
            order_items.append(f"{item} x{quantity}")
            total_amount += price * quantity
        
        # Add delivery charge and taxes
        delivery_charge = random.randint(30, 80)
        tax = round(total_amount * 0.05, 2)
        total_amount = round(total_amount + delivery_charge + tax, 2)
        
        # Order date and time (more orders during meal times)
        order_date = fake.date_between(start_date=start_date, end_date=end_date)
        
        # Peak hours: 12-2 PM (lunch), 7-10 PM (dinner)
        hour_weights = [1] * 24
        hour_weights[12] = hour_weights[13] = hour_weights[19] = hour_weights[20] = hour_weights[21] = 5
        
        hour = random.choices(range(24), weights=hour_weights, k=1)[0]
        minute = random.randint(0, 59)
        order_time = f"{hour:02d}:{minute:02d}:00"
        
        # Order status (most orders completed)
        order_status = random.choices(
            ORDER_STATUSES,
            weights=[0.05, 0.1, 0.15, 0.1, 0.55, 0.05],
            k=1
        )[0]
        
        orders.append([order_id, customer_id, restaurant_id, "; ".join(order_items), order_date, order_time, order_status, total_amount])
    
    with open('zomato_orders.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['order_id', 'customer_id', 'restaurant_id', 'order_item', 'order_date', 'order_time', 'order_status', 'total_amount'])
        writer.writerows(orders)
    
    print(f"Generated orders data: {len(orders)} records")
    return orders

def generate_delivery_data(orders, riders, num_records=20000):
    """Generate delivery data"""
    deliveries = []
    
    for i, order in enumerate(orders[:num_records], 1):
        delivery_id = i
        order_id = order[0]
        order_date_str = order[4]
        order_time_str = order[5]
        order_status = order[6]
        
        # Only create delivery records for orders that are not cancelled
        if order_status == "Cancelled":
            continue
        
        rider = random.choice(riders)
        rider_id = rider[0]
        
        # Delivery status based on order status
        if order_status in ["Pending", "Confirmed"]:
            delivery_status = "Assigned"
        elif order_status == "Preparing":
            delivery_status = random.choice(["Assigned", "Picked Up"])
        elif order_status == "Ready for Pickup":
            delivery_status = random.choice(["Picked Up", "In Transit"])
        else:  # Completed
            delivery_status = "Delivered"
        
        # Calculate delivery time (order time + 20-60 minutes)
        order_datetime = datetime.strptime(f"{order_date_str} {order_time_str}", '%Y-%m-%d %H:%M:%S')
        delivery_minutes = random.randint(20, 60)
        delivery_datetime = order_datetime + timedelta(minutes=delivery_minutes)
        delivery_time = delivery_datetime.strftime('%Y-%m-%d %H:%M:%S')
        
        deliveries.append([delivery_id, order_id, delivery_status, delivery_time, rider_id])
    
    # If we have fewer deliveries due to cancelled orders, create more
    if len(deliveries) < num_records:
        additional_needed = num_records - len(deliveries)
        for i in range(additional_needed):
            delivery_id = len(deliveries) + i + 1
            order = random.choice(orders)
            order_id = order[0]
            rider = random.choice(riders)
            rider_id = rider[0]
            delivery_status = random.choice(DELIVERY_STATUSES)
            
            order_date_str = order[4]
            order_time_str = order[5]
            order_datetime = datetime.strptime(f"{order_date_str} {order_time_str}", '%Y-%m-%d %H:%M:%S')
            delivery_minutes = random.randint(20, 60)
            delivery_datetime = order_datetime + timedelta(minutes=delivery_minutes)
            delivery_time = delivery_datetime.strftime('%Y-%m-%d %H:%M:%S')
            
            deliveries.append([delivery_id, order_id, delivery_status, delivery_time, rider_id])
    
    with open('zomato_delivery.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['delivery_id', 'order_id', 'delivery_status', 'delivery_time', 'rider_id'])
        writer.writerows(deliveries)
    
    print(f"Generated delivery data: {len(deliveries)} records")
    return deliveries

def main():
    """Main function to generate all Zomato data"""
    print("Generating Zomato sales data...")
    
    # Generate data
    customers = generate_customers_data()
    restaurants = generate_restaurants_data()
    riders = generate_riders_data()
    orders = generate_orders_data(customers, restaurants)
    deliveries = generate_delivery_data(orders, riders)
    
    print("Zomato data generation completed!")
    print(f"Total customers: {len(customers)}")
    print(f"Total restaurants: {len(restaurants)}")
    print(f"Total riders: {len(riders)}")
    print(f"Total orders: {len(orders)}")
    print(f"Total deliveries: {len(deliveries)}")

if __name__ == "__main__":
    main()
