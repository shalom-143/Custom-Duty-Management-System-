const getRate = async (req, res) => {
  const { hsCode, date } = req.query;
  const rate = await dutyRateService.getActiveRate(hsCode, date);
  res.json(rate);
}
