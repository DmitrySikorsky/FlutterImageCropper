// Copyright © 2022 Dmitry Sikorsky. All rights reserved.
// Licensed under the Apache License, Version 2.0. See License.txt in the project root for license information.

import 'package:flutter/material.dart';

class Cropping {
  final Rect? source;
  final Size? destination;

  const Cropping({
    this.source,
    this.destination,
  });
}
