DELIMITER //

CREATE PROCEDURE ProcessEquipmentPurchase(
    IN p_patient_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);
    DECLARE v_balance DECIMAL(18,2);
    DECLARE v_status VARCHAR(20);
    DECLARE v_total DECIMAL(18,2);

    -- Lấy thông tin sản phẩm
    SELECT stock, price INTO v_stock, v_price
    FROM Products
    WHERE product_id = p_product_id;

    -- Lấy thông tin ví
    SELECT balance, status INTO v_balance, v_status
    FROM Wallets
    WHERE patient_id = p_patient_id;

    SET v_total = p_quantity * v_price;

    START TRANSACTION;

    -- Kiểm tra điều kiện
    IF v_stock < p_quantity THEN
        ROLLBACK;
        SET p_message = 'Thất bại: Kho không đủ sản phẩm';
    ELSEIF v_status = 'Inactive' THEN
        ROLLBACK;
        SET p_message = 'Thất bại: Ví đang bị khóa';
    ELSEIF v_balance < v_total THEN
        ROLLBACK;
        SET p_message = 'Thất bại: Số dư ví không đủ';
    ELSE
        -- Trừ tồn kho
        UPDATE Products
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;

        -- Trừ tiền ví
        UPDATE Wallets
        SET balance = balance - v_total
        WHERE patient_id = p_patient_id;

        COMMIT;
        SET p_message = 'Thành công: Đã xử lý đơn hàng';
    END IF;
END //

DELIMITER ;
CALL ProcessEquipmentPurchase(1, 1, 999, @msg);
SELECT @msg;
-- "Thất bại: Kho không đủ sản phẩm"
CALL ProcessEquipmentPurchase(1, 1, 999, @msg);
SELECT @msg;
-- "Thất bại: Kho không đủ sản phẩm"
	CALL ProcessEquipmentPurchase(2, 1, 5, @msg);
SELECT @msg;
-- "Thất bại: Số dư ví không đủ"
CALL ProcessEquipmentPurchase(3, 1, 1, @msg);
SELECT @msg;
-- "Thất bại: Ví đang bị khóa"
	