const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');

async function generateInvoicePDF({ order, orderItems, invoiceNumber }) {
  // Save invoices in uploads/invoice at the project root
  const uploadsDir = path.resolve(__dirname, '../../uploads/invoice');
  if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
  const filePath = path.join(uploadsDir, `${invoiceNumber}.pdf`);
  const doc = new PDFDocument({ margin: 30 });
  const stream = doc.pipe(fs.createWriteStream(filePath));

  // Header
  doc.fontSize(18).fillColor('#1565c0').text('Areeva Products & Services Pvt. Ltd.', { align: 'center' });
  doc.moveDown(0.2);
  doc.fontSize(10).fillColor('black').text('Hari Nagar, New Delhi, Delhi 110058, India', { align: 'center' });
  doc.text('Ph: 9810162596', { align: 'center' });
  doc.text('Email: shop.westdelhi@shoppurs.in', { align: 'center' });
  doc.text('GSTIN: 07AAPCA4055P1Z3', { align: 'center' });
  doc.moveDown(1);

  // --- Purchase Details ---
  let y = doc.y;
  doc.fontSize(12).fillColor('#1565c0').text('Purchase Details', 30, y);
  y += 18;
  doc.fontSize(9).fillColor('black').text(`Transaction id: ${order.ORDER_NUMBER || ''}`, 30, y);
  y += 13;
  doc.text(`Date: ${(order.CREATED_DATE || '').toISOString ? order.CREATED_DATE.toISOString().slice(0, 19).replace('T', ' ') : order.CREATED_DATE}`, 30, y);
  y += 18;

  // --- Summary and Payment Details ---
  // Draw rectangles
  doc.rect(30, y, 250, 60).fill('#e3f2fd').stroke();
  doc.rect(300, y, 200, 60).fill('#f5f5f5').stroke();
  // Purchase Summary
  doc.fillColor('#1565c0').fontSize(11).text('Purchase Summary', 35, y + 5);
  doc.fillColor('black').fontSize(9).text(`Total Amount: ${order.ORDER_TOTAL || ''}`, 35, y + 22);
  doc.text(`Items: ${orderItems.length}`, 35, y + 35);
  doc.text(`Discounted Items: 0`, 35, y + 48);
  // Payment Details
  doc.fillColor('#1565c0').fontSize(11).text('Payment Details', 305, y + 5);
  doc.fillColor('black').fontSize(9).text('Payment Method: Cash', 305, y + 22);
  doc.text('Amount: ' + (order.ORDER_TOTAL || ''), 305, y + 35);
  y += 70;

  // --- Item Table Header ---
  doc.moveTo(30, y).lineTo(500, y).stroke();
  y += 5;
  doc.fontSize(10).fillColor('black');
  doc.text('Item Name', 30, y);
  doc.text('Qty', 200, y);
  doc.text('Net Amt', 250, y);
  doc.text('HSN', 310, y);
  doc.text('MRP', 370, y);
  doc.text('CGST%', 420, y);
  doc.text('SGST%', 470, y);
  y += 15;
  doc.moveTo(30, y).lineTo(500, y).stroke();
  y += 5;

  // --- Item Table Rows ---
  orderItems.forEach(item => {
    doc.fontSize(9).text(item.PROD_NAME, 30, y, { width: 160 });
    doc.text(item.QUANTITY, 200, y);
    doc.text(item.TOTAL_PRICE, 250, y);
    doc.text(item.PROD_HSN_CODE || '', 310, y);
    doc.text(item.PROD_MRP || '', 370, y);
    doc.text('6', 420, y);
    doc.text('6', 470, y);
    y += 15;
  });
  y += 5;
  doc.fontSize(9).text('Total Amount', 200, y);
  doc.text(order.ORDER_TOTAL || '', 250, y);
  y += 13;
  doc.text('Gross Total', 200, y);
  doc.text(order.ORDER_TOTAL || '', 250, y);
  y += 20;

  // --- GST Summary ---
  doc.fontSize(10).text('GST', 30, y);
  doc.text('Taxable Value', 100, y);
  doc.text('Tax(%)', 200, y);
  doc.text('Tax Amt', 300, y);
  y += 13;
  doc.fontSize(9).text('CGST', 30, y);
  doc.text('1,321.39', 100, y);
  doc.text('6', 200, y);
  doc.text('79.28', 300, y);
  y += 13;
  doc.text('SGST', 30, y);
  doc.text('1,321.39', 100, y);
  doc.text('6', 200, y);
  doc.text('79.28', 300, y);
  y += 13;
  doc.text('Total Tax', 200, y);
  doc.text('243.37', 300, y);
  y += 20;

  // --- Customer and Store Details ---
  doc.fontSize(11).fillColor('#1565c0').text('CUSTOMER DETAILS', 30, y);
  y += 15;
  doc.fontSize(9).fillColor('black').text(`${order.USERNAME}\n${order.MOBILE}`, 30, y);
  y += 25;
  doc.fontSize(11).fillColor('#1565c0').text('STORE DETAILS', 30, y);
  y += 15;
  doc.fontSize(9).fillColor('black').text('Areeva Products & Services Pvt. Ltd.\nHari Nagar, New Delhi, Delhi 110058, India\nPh: 9810162596\nEmail: shop.westdelhi@shoppurs.in\nGSTIN: 07AAPCA4055P1Z3', 30, y);
  y += 50;

  // --- Footer and QR code ---
  doc.fontSize(10).fillColor('black').text('Tax Invoice No: ' + invoiceNumber, 30, y, { align: 'left' });
  y += 15;
  // Generate QR code for invoice number
  const qrData = await QRCode.toDataURL(invoiceNumber);
  doc.image(qrData, 400, y - 10, { width: 80, height: 80 });
  y += 70;
  doc.fontSize(9).fillColor('black').text('Thank you for shopping at Shoppurs.\nIn case you would like to Exchange any of the products purchased, we request you to carry your bill along. It will be our pleasure to serve you again.', 30, y, { align: 'left' });

  doc.end();

  // Wait for the file to be fully written
  await new Promise((resolve, reject) => {
    stream.on('finish', resolve);
    stream.on('error', reject);
  });

  return filePath;
}

module.exports = { generateInvoicePDF }; 