#pragma once

#include "Stage8/MotorBridge/MotorBridgeComponentAc.hpp"
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <string>

namespace Stage8 {

class MotorBridgeComponent final : public MotorBridgeComponentBase {
public:
  MotorBridgeComponent(const char* compName);
  ~MotorBridgeComponent();

  void init(const NATIVE_INT_TYPE queueDepth, const NATIVE_INT_TYPE instance = 0);

private:
  // ===== F´ Command Handlers (MUST match generated signatures) =====

  void SetDuty_cmdHandler(
    const FwOpcodeType opCode,
    const U32 cmdSeq,
    F32 duty
  ) override;

  void Enable_cmdHandler(
    const FwOpcodeType opCode,
    const U32 cmdSeq
  ) override;

  void Disable_cmdHandler(
    const FwOpcodeType opCode,
    const U32 cmdSeq
  ) override;

  // ===== Internal ramping worker =====
  void workerThread();
  bool sendToJulia(const std::string& msg);

private:
  std::thread m_thread;
  std::atomic<bool> m_running{false};
  std::mutex m_mutex;
  std::condition_variable m_cv;

  F32 m_targetDuty{0.0f};
  F32 m_currentDuty{0.0f};
  bool m_enabled{false};

  // TCP settings to Julia server
  std::string m_host{"127.0.0.1"};
  U16 m_port{5050};
};

} // namespace Stage8
