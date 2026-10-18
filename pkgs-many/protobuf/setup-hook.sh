ProtobufCMakeFlags() {
  # Only set cmake entries when cmake is available
  if declare -F setCMakeEntry > /dev/null; then
    setCMakeEntry PROTOC_EXE "@build_protobuf@/bin/protoc"
    setCMakeEntry Protobuf_PROTOC_EXE "@build_protobuf@/bin/protoc"
    setCMakeEntry Protobuf_PROTOC_EXECUTABLE "@build_protobuf@/bin/protoc"
  fi
}

preConfigureHooks+=(ProtobufCMakeFlags)
