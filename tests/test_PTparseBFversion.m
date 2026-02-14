% test_PTparseBFversion.m - tests for PTparseBFversion

%!test
%! % BF 4.5.3
%! si = {'Firmware version', ' Betaflight / STM32F405 4.5.3 Dec 14 2024 / 11:27:01'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'Betaflight'));
%! assert(maj, 4);
%! assert(mnr, 5);

%!test
%! % BF 2025.12.2 (CalVer)
%! si = {'Firmware version', ' Betaflight / STM32H743 2025.12.2 Jan 5 2026 / 09:15:00'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'Betaflight'));
%! assert(maj, 2025);
%! assert(mnr, 12);

%!test
%! % INAV 7.1.0
%! si = {'Firmware version', ' INAV / STM32F405 7.1.0 Aug 2024'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'INAV'));
%! assert(maj, 7);
%! assert(mnr, 1);

%!test
%! % Emuflight 0.4.1
%! si = {'Firmware version', ' Emuflight / STM32F411 0.4.1 Mar 2023'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'Emuflight'));

%!test
%! % Malformed / missing version row
%! si = {'other_param', 'some_value'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'Unknown'));
%! assert(maj, 0);
%! assert(mnr, 0);

%!test
%! % Firmware revision (alternate key)
%! si = {'Firmware revision', ' Betaflight / STM32F7X2 4.4.0 Jun 2024'};
%! [t, maj, mnr] = PTparseBFversion(si);
%! assert(strcmp(t, 'Betaflight'));
%! assert(maj, 4);
%! assert(mnr, 4);
