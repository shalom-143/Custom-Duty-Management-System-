const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const createInspection = async (req, res) => {
  const { shipment_id, officer_id, inspection_date, inspection_type, outcome, notes } = req.body;

  if (!shipment_id || !officer_id || !inspection_date) {
    return res.status(400).json({ error: "Missing required fields: shipment_id, officer_id, and inspection_date are mandatory." });
  }

  try {
    const newInspection = await prisma.inspection.create({
      data: {
        shipment_id: parseInt(shipment_id),
        officer_id: parseInt(officer_id),
        inspection_date: new Date(inspection_date),
        inspection_type,
        outcome,
        notes,
      },
    });
    res.status(201).json({ message: "Inspection record created successfully", data: newInspection });
  } catch (error) {
    res.status(500).json({ error: "Database transaction failed", details: error.message });
  }
};

const getAllInspections = async (req, res) => {
  try {
    const inspections = await prisma.inspection.findMany({
      orderBy: {
        inspection_date: 'desc',
      },
    });
    res.status(200).json({ count: inspections.length, data: inspections });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch inspection records", details: error.message });
  }
};

const updateInspection = async (req, res) => {
  const { id } = req.params;
  const { inspection_type, outcome, notes } = req.body;

  try {
    const updatedInspection = await prisma.inspection.update({
      where: { inspection_id: parseInt(id) },
      data: {
        inspection_type,
        outcome,
        notes,
      },
    });
    res.status(200).json({ message: "Inspection record updated successfully", data: updatedInspection });
  } catch (error) {
    res.status(500).json({ error: "Failed to update inspection record", details: error.message });
  }
};

const deleteInspection = async (req, res) => {
  const { id } = req.params;

  try {
    await prisma.inspection.delete({
      where: { inspection_id: parseInt(id) },
    });
    res.status(200).json({ message: "Inspection record deleted cleanly." });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete inspection record", details: error.message });
  }
};

module.exports = {
  createInspection,
  getAllInspections,
  updateInspection,
  deleteInspection,
};
