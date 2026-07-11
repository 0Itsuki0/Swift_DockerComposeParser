//
//  ServiceGpusTestSuite.swift
//  DockerComposeParser
//
//  Created by Itsuki on 2026/07/11.
//

@testable import DockerComposeParser
import Testing
import Yams



@Suite("ServiceGpus Parsing Tests")
struct ServiceGpusTestSuite {

    @Test("Test GPU parsing - 'all' string")
    func parseAllString() throws {
        let node = try Yams.compose(yaml: "all")
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == true)
        #expect(gpu.devices == nil)
    }

    @Test("Test GPU parsing - list of device requests")
    func parseDeviceList() throws {
        let yaml = """
            - driver: nvidia
              count: 1
              capabilities: ["gpu"]
            - driver: nvidia
              device_ids: ["0"]
            """
        let node = try Yams.compose(yaml: yaml)
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == false)
        #expect(gpu.devices?.count == 2)
        #expect(gpu.devices?[0].driver == "nvidia")
        #expect(gpu.devices?[0].count == 1)
        #expect(gpu.devices?[1].device_ids == ["0"])
    }

    @Test("Test GPU parsing - single device request (non-array node)")
    func parseSingleDevice() throws {
        let yaml = """
            driver: nvidia
            count: 1
            """
        let node = try Yams.compose(yaml: yaml)
        let gpu = try Service.GPU(node!, envs: [:])
        #expect(gpu.all == false)
        #expect(gpu.devices?.count == 1)
        #expect(gpu.devices?.first?.driver == "nvidia")
    }

    @Test(
        "Test GPU parsing - string other than 'all' is treated as device list, throws"
    )
    func parseNonAllString() throws {
        let node = try Yams.compose(yaml: "none")
        #expect(throws: (any Error).self) {
            try Service.GPU(node!, envs: [:])
        }
    }
}
