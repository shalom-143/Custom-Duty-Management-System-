const dutyRate = await dutyRateService.getActiveRate(hsCode, shipmentDate);
const dutyAmount = declaredValue * (dutyRate.duty_percentage / 100);
const vatAmount = declaredValue * (dutyRate.vat_rate / 100);
// return totals
