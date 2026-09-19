function q = PSnotchQ(center_hz, cutoff_hz)
%% PSnotchQ - quality factor BF derives from a notch centre and cutoff
%  Mirrors filterGetNotchQ in BF common/filter.c. The cutoff is the lower
%  -3 dB corner of the notch, which is what sets how wide it is and so how
%  much delay it costs.
%
%  Returns 0 when the pair cannot describe a notch - the firmware skips the
%  filter on a zero cutoff, and a cutoff at or above the centre has no meaning.

if center_hz <= 0 || cutoff_hz <= 0 || cutoff_hz >= center_hz
    q = 0;
    return
end

q = center_hz * cutoff_hz / (center_hz^2 - cutoff_hz^2);

end
