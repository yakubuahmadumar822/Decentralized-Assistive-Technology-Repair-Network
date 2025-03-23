import { describe, it, expect, beforeEach } from "vitest"

// Mock implementation for testing Clarity contracts
const mockPrincipal = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockTechnicianPrincipal = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockBlockHeight = 100

// Mock state
let lastDeviceId = 0
let lastHistoryId = 0
const devices = new Map()
const deviceHistory = new Map()

// Mock contract functions
const registerDevice = (
    deviceType,
    manufacturer,
    model,
    serialNumber,
    year,
    issueDescription,
    urgencyLevel,
    location,
    images
) => {
  const newId = lastDeviceId + 1
  lastDeviceId = newId
  
  devices.set(newId, {
    owner: mockPrincipal,
    "device-type": deviceType,
    manufacturer,
    model,
    "serial-number": serialNumber,
    year,
    "issue-description": issueDescription,
    "urgency-level": urgencyLevel,
    location,
    images,
    status: "registered",
    "registration-date": mockBlockHeight
  })
  
  // Add initial history entry
  addHistoryEntry(newId, "registered", "Device registered for repair")
  
  return { value: newId }
}

const updateDeviceInfo = (
    deviceId,
    issueDescription,
    urgencyLevel,
    location,
    images
) => {
  const device = devices.get(deviceId)
  if (!device) return { error: 404 }
  if (device.owner !== mockPrincipal) return { error: 403 }
  
  devices.set(deviceId, {
    ...device,
    "issue-description": issueDescription,
    "urgency-level": urgencyLevel,
    location,
    images
  })
  
  // Add history entry
  addHistoryEntry(deviceId, device.status, "Device information updated")
  
  return { value: deviceId }
}

const updateDeviceStatus = (
    deviceId,
    status,
    notes
) => {
  const device = devices.get(deviceId)
  if (!device) return { error: 404 }
  
  // Check if caller is owner or authorized technician
  if (device.owner !== mockPrincipal && !isAuthorizedTechnician(mockPrincipal, deviceId)) {
    return { error: 403 }
  }
  
  devices.set(deviceId, {
    ...device,
    status
  })
  
  // Add history entry
  addHistoryEntry(deviceId, status, notes)
  
  return { value: deviceId }
}

const addHistoryEntry = (deviceId, status, notes) => {
  const newId = lastHistoryId + 1
  lastHistoryId = newId
  
  deviceHistory.set(newId, {
    "device-id": deviceId,
    status,
    notes,
    "updated-by": mockPrincipal,
    timestamp: mockBlockHeight
  })
  
  return newId
}

const isAuthorizedTechnician = (technician, deviceId) => {
  // In a real implementation, this would check if the technician is assigned to this device
  // For simplicity, we're returning false
  return false
}

const getDevice = (deviceId) => {
  const device = devices.get(deviceId)
  return device ? device : null
}

const getDeviceHistory = (deviceId) => {
  // In a real implementation, this would return all history entries for the device
  // For simplicity, we're returning an empty list
  return []
}

describe("Device Registration Contract", () => {
  beforeEach(() => {
    // Reset state before each test
    lastDeviceId = 0
    lastHistoryId = 0
    devices.clear()
    deviceHistory.clear()
  })
  
  it("should register a device", () => {
    const result = registerDevice(
        "Wheelchair",
        "Sunrise Medical",
        "Quickie 2",
        "QK2-12345",
        2018,
        "Right wheel bearing is making noise and wheel wobbles",
        "medium",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg"
    )
    
    expect(result.value).toBe(1)
    expect(devices.size).toBe(1)
    
    const device = getDevice(1)
    expect(device).not.toBeNull()
    expect(device["device-type"]).toBe("Wheelchair")
    expect(device.manufacturer).toBe("Sunrise Medical")
    expect(device.model).toBe("Quickie 2")
    expect(device["serial-number"]).toBe("QK2-12345")
    expect(device.year).toBe(2018)
    expect(device["issue-description"]).toBe("Right wheel bearing is making noise and wheel wobbles")
    expect(device["urgency-level"]).toBe("medium")
    expect(device.status).toBe("registered")
  })
  
  it("should update device information", () => {
    // First register a device
    registerDevice(
        "Wheelchair",
        "Sunrise Medical",
        "Quickie 2",
        "QK2-12345",
        2018,
        "Right wheel bearing is making noise and wheel wobbles",
        "medium",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg"
    )
    
    // Then update it
    const updateResult = updateDeviceInfo(
        1,
        "Right wheel bearing is making noise, wheel wobbles, and now brake is also not engaging properly",
        "high",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg,https://example.com/wheelchair-image3.jpg"
    )
    
    expect(updateResult.value).toBe(1)
    
    const device = getDevice(1)
    expect(device["issue-description"]).toBe("Right wheel bearing is making noise, wheel wobbles, and now brake is also not engaging properly")
    expect(device["urgency-level"]).toBe("high")
    expect(device.images).toBe("https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg,https://example.com/wheelchair-image3.jpg")
  })
  
  it("should update device status", () => {
    // First register a device
    registerDevice(
        "Wheelchair",
        "Sunrise Medical",
        "Quickie 2",
        "QK2-12345",
        2018,
        "Right wheel bearing is making noise and wheel wobbles",
        "medium",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg"
    )
    
    // Then update its status
    const updateResult = updateDeviceStatus(
        1,
        "matched",
        "Device matched with technician John Smith"
    )
    
    expect(updateResult.value).toBe(1)
    
    const device = getDevice(1)
    expect(device.status).toBe("matched")
  })
  
  it("should fail to update a non-existent device", () => {
    const updateResult = updateDeviceInfo(
        999,
        "Right wheel bearing is making noise, wheel wobbles, and now brake is also not engaging properly",
        "high",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg,https://example.com/wheelchair-image3.jpg"
    )
    
    expect(updateResult.error).toBe(404)
  })
  
  it("should fail to update a device if not the owner", () => {
    // First register a device
    registerDevice(
        "Wheelchair",
        "Sunrise Medical",
        "Quickie 2",
        "QK2-12345",
        2018,
        "Right wheel bearing is making noise and wheel wobbles",
        "medium",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg"
    )
    
    // Modify the owner to simulate a different user
    const device = devices.get(1)
    devices.set(1, { ...device, owner: "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM" })
    
    // Then try to update it
    const updateResult = updateDeviceInfo(
        1,
        "Right wheel bearing is making noise, wheel wobbles, and now brake is also not engaging properly",
        "high",
        "123 Main St, Anytown, USA",
        "https://example.com/wheelchair-image1.jpg,https://example.com/wheelchair-image2.jpg,https://example.com/wheelchair-image3.jpg"
    )
    
    expect(updateResult.error).toBe(403)
  })
})
