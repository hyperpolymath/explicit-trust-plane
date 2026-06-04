-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
||| EXPLICIT-TRUST-PLANE — ABI Type Definitions
|||
||| This module defines the Application Binary Interface for the 
||| Trust Plane protocol. It provides the formal foundations for 
||| cross-node capability propagation and identity validation.

module EXPLICIT_TRUST_PLANE.ABI.Types

import Data.Bits
import Data.So
import Data.Vect

%default total

--------------------------------------------------------------------------------
-- Platform Context
--------------------------------------------------------------------------------

||| Supported targets for the Trust Plane kernel.
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Resolves the execution environment at compile time.
public export
thisPlatform : Platform
thisPlatform =
  %runElab do
    pure Linux

--------------------------------------------------------------------------------
-- Core Result Types
--------------------------------------------------------------------------------

||| Formal outcome of a trust negotiation.
public export
data Result : Type where
  ||| Negotiation Successful
  Ok : Result
  ||| Negotiation Failed: Untrusted peer
  Error : Result
  ||| Invalid Parameter: malformed capability
  InvalidParam : Result
  ||| System Error: out of memory
  OutOfMemory : Result
  ||| Safety Error: null pointer encountered
  NullPointer : Result

--------------------------------------------------------------------------------
-- Safety Handles
--------------------------------------------------------------------------------

||| Opaque handle to a Trust Plane session.
||| INVARIANT: The internal pointer is guaranteed to be non-null.
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

||| Safe constructor for handles.
public export
createHandle : Bits64 -> Maybe Handle
createHandle 0 = Nothing
createHandle ptr = Just (MkHandle ptr)
