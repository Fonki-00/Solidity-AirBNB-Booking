// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract AirbnbBooking {
    enum BookingStatus { Available, Booked, Completed, Canceled }

    struct Booking {
        address tenant;
        uint256 checkInDate;
        uint256 checkOutDate;
        uint256 totalPrice;
        BookingStatus status;
    }

    address public owner;
    uint256 public pricePerNight;
    mapping(address => mapping(uint256 => Booking)) public tenantBookings;
    mapping(uint256 => Booking) public bookings;
    uint256 public nextBookingId;

    event BookingCreated(uint256 indexed bookingId, address indexed tenant, uint256 checkInDate, uint256 checkOutDate, uint256 totalPrice);
    event BookingCanceled(uint256 indexed bookingId);
    event BookingCompleted(uint256 indexed bookingId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint256 _pricePerNight) {
        owner = msg.sender;
        pricePerNight = _pricePerNight;
    }

    function book(uint256 _checkInDate, uint256 _checkOutDate) external payable {
        require(_checkOutDate > _checkInDate, "Invalid date range");
        uint256 numberOfNights = (_checkOutDate - _checkInDate) / 1 days;
        uint256 totalPrice = numberOfNights * pricePerNight;
        require(msg.value == totalPrice, "Incorrect payment amount");

        for (uint256 i = _checkInDate; i < _checkOutDate; i += 1 days) {
            require(bookings[i].status == BookingStatus.Available, "Dates not available");
        }

        uint256 bookingId = nextBookingId++;
        bookings[bookingId] = Booking(msg.sender, _checkInDate, _checkOutDate, totalPrice, BookingStatus.Booked);
        tenantBookings[msg.sender][bookingId] = bookings[bookingId];

        emit BookingCreated(bookingId, msg.sender, _checkInDate, _checkOutDate, totalPrice);
    }

    function cancelBooking(uint256 _bookingId) external {
        Booking storage booking = bookings[_bookingId];
        require(booking.tenant == msg.sender, "You are not authorized to cancel this booking");
        require(booking.status == BookingStatus.Booked, "Booking cannot be canceled");

        booking.status = BookingStatus.Canceled;
        payable(msg.sender).transfer(booking.totalPrice);

        emit BookingCanceled(_bookingId);
    }

    function completeBooking(uint256 _bookingId) external onlyOwner {
        Booking storage booking = bookings[_bookingId];
        require(booking.status == BookingStatus.Booked, "Booking is not in progress");

        booking.status = BookingStatus.Completed;

        emit BookingCompleted(_bookingId);
    }

    function getBookingStatus(uint256 _bookingId) external view returns (BookingStatus) {
        return bookings[_bookingId].status;
    }

    function getPricePerNight() external view returns (uint256) {
        return pricePerNight;
    }

    receive() external payable {}
}