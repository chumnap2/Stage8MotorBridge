#include "MotorBridgeComponent.hpp"

#include <cstdio>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <chrono>
#include <algorithm>

namespace Stage8 {

// =======================================================
// Constructor / Destructor
// =======================================================

MotorBridgeComponent::MotorBridgeComponent(const char* compName) :
  MotorBridgeComponentBase(compName)
{
}

MotorBridgeComponent::~MotorBridgeComponent() {
  m_running = false;
  m_cv.notify_all();
  if (m_thread.joinable()) {
    m_thread.join();
  }
}

void MotorBridgeComponent::init(const NATIVE_INT_TYPE queueDepth, const NATIVE_INT_TYPE instance) {
  MotorBridgeComponentBase::init(queueDepth, instance);
  m_running = true;
  m_thread = std::thread(&MotorBridgeComponent::workerThread, this);
}

// =======================================================
// TCP Sender to Julia
// =======================================================

bool MotorBridgeComponent::sendToJulia(const std::string& msg) {

  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) return false;

  struct sockaddr_in serv_addr;
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(m_port);

  if (inet_pton(AF_INET, m_host.c_str(), &serv_addr.sin_addr) <= 0) {
    close(sock);
    return false;
  }

  // short timeout
  struct timeval tv;
  tv.tv_sec = 0;
  tv.tv_usec = 200000; // 200ms
  setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof tv);

  if (connect(sock, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
    close(sock);
    return false;
  }

  send(sock, msg.c_str(), msg.size(), 0);
  close(sock);
  return true;
}

// =======================================================
// F´ Command Handlers
// =======================================================

void MotorBridgeComponent::Enable_cmdHandler(FwOpcodeType opCode, U32 cmdSeq) {
  m_enabled = true;
  log_ACTIVITY_LO_MotorEnabled();
  this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

void MotorBridgeComponent::Disable_cmdHandler(FwOpcodeType opCode, U32 cmdSeq) {
  m_enabled = false;
  m_targetDuty = 0.0f;
  log_ACTIVITY_LO_MotorDisabled();
  this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

void MotorBridgeComponent::SetDuty_cmdHandler(FwOpcodeType opCode, U32 cmdSeq, F32 duty) {

  if (!m_enabled) {
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
    return;
  }

  m_targetDuty = duty;
  log_ACTIVITY_HI_DutyUpdated(duty);
  this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

// =======================================================
// Worker Ramp Thread
// =======================================================

void MotorBridgeComponent::workerThread() {
  using namespace std::chrono_literals;

  const F32 rampStep = 0.01f;   // per cycle
  const auto period = 20ms;     // 50Hz

  while (m_running) {
    std::unique_lock<std::mutex> lk(m_mutex);
    m_cv.wait_for(lk, period);

    if (!m_enabled) {
      if (m_currentDuty > 0.0f) m_currentDuty = std::max(0.0f, m_currentDuty - rampStep);
      else if (m_currentDuty < 0.0f) m_currentDuty = std::min(0.0f, m_currentDuty + rampStep);
    } else {
      if (m_currentDuty < m_targetDuty)
        m_currentDuty = std::min(m_targetDuty, m_currentDuty + rampStep);
      else if (m_currentDuty > m_targetDuty)
        m_currentDuty = std::max(m_targetDuty, m_currentDuty - rampStep);
    }

    // Publish telemetry
    tlmWrite_CurrentDuty(m_currentDuty);

    // Forward to Julia server
    char buf[64];
    std::snprintf(buf, sizeof(buf), "SET_DUTY:%f\n", (double)m_currentDuty);
    sendToJulia(buf);
  }
}

} // namespace Stage8
