/*
 * Copyright 2012-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.vet;

import io.opentracing.Scope;
import io.opentracing.Span;
import io.opentracing.Tracer;
import io.opentracing.tag.Tags;
import io.opentracing.util.GlobalTracer;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.FileNotFoundException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.locks.LockSupport;

/**
 * @author Juergen Hoeller
 * @author Mark Fisher
 * @author Ken Krebs
 * @author Arjen Poutsma
 */
@Controller
class VetController {

	private static final long VETS_ASYNC_NB = Long.getLong("vetsAsyncs", 1);

	private static final long VETS_ASYNC_SLEEP_MS = Long.getLong("vetsAsyncSleep", 500);

	private static final int VETS_SYNTHETIC_SPAN_NB = Integer.getInteger("vetsSyntheticSpans", 0);

	private static final int VETS_SYNTHETIC_SPAN_SLEEP_MS = Integer.getInteger("vetsSyntheticSpanSleep", 10);

	private static final int VETS_SYNTHETIC_CPU_PERIOD = Integer.getInteger("vetsSyntheticCpu", 0);

	private static final int VETS_SYNTHETIC_SLEEP_MS = Integer.getInteger("vetsSyntheticSleep", 10);

	private static final int VETS_SYNTHETIC_GARBAGE = Integer.getInteger("vetsSyntheticGarbage", 0);

	private static final int VETS_SYNTHETIC_GARBAGE_RETAIN_S = Integer.getInteger("vetsSyntheticGarbageRetain", 10);

	private static final int VETS_SYNTHETIC_LIVESET = Integer.getInteger("vetsSyntheticLiveSet", 0);

	private static final int VETS_SYNTHETIC_EXCEPTIONS = Integer.getInteger("vetsSyntheticExceptions", 0);

	private final VetRepository vets;

	private int result;

	private List<Object> garbage = new ArrayList<>();

	private long garbageStart;

	private AtomicReference syntheticLiveSet = new AtomicReference();

	private final ExecutorService executor = Executors.newSingleThreadExecutor(r -> new Thread(r, "VetsExecutor"));

	private final ExecutorService exceptionExecutor = Executors
			.newSingleThreadExecutor(r -> new Thread(r, "VetsExceptionExecutor"));

	public VetController(VetRepository clinicService) {
		this.vets = clinicService;
	}

	@GetMapping("/vets.html")
	public String showVetList(Map<String, Object> model) {
		// Here we are returning an object of type 'Vets' rather than a collection of Vet
		// objects so it is simpler for Object-Xml mapping
		Vets vets = new Vets();
		vets.getVetList().addAll(this.vets.findAll());
		// synthetic spans
		for (int i = 0; i < VETS_SYNTHETIC_SPAN_NB; i++) {
			syntheticSpan();
		}
		// synthetic cpu
		if (VETS_SYNTHETIC_CPU_PERIOD > 0) {
			result = syntheticCpu();
		}
		// syntheticSleep
		if (VETS_SYNTHETIC_SLEEP_MS > 0) {
			syntheticSleep();
		}
		// asyncs
		if (VETS_ASYNC_NB > 0) {
			asyncs();
		}
		if (VETS_SYNTHETIC_GARBAGE > 0) {
			syntheticGarbage();
		}
		if (VETS_SYNTHETIC_LIVESET > 0) {
			syntheticLiveSet();
		}
		if (VETS_SYNTHETIC_EXCEPTIONS > 0) {
			syntheticExceptions();
		}
		model.put("vets", vets);
		return "vets/vetList";
	}

	private void syntheticExceptions() {
        for (int i = 0; i < VETS_SYNTHETIC_EXCEPTIONS; i++) {
            try {
                throw new FileNotFoundException();
            }
            catch (Exception ex) {
                // swallow exceptions
            }
        }
    }

	private void syntheticLiveSet() {
		if (syntheticLiveSet.get() != null) {
			return;
		}
		final String alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
		List<Map<String, String>> list = new ArrayList<>();
		for (int i = 0; i < VETS_SYNTHETIC_LIVESET; i++) {
			Map<String, String> map = new HashMap<>();
			for (int j = 0; j < 8192; j++) {
				map.put(alpha + j, alpha + j);
			}
			list.add(map);
		}
		syntheticLiveSet.compareAndSet(null, list);
	}

	private void syntheticGarbage() {
		long now = System.currentTimeMillis();
		if (now - garbageStart > VETS_SYNTHETIC_GARBAGE_RETAIN_S * 1000) {
			garbage = new ArrayList<>();
			garbageStart = now;
		}
		for (int i = 0; i < VETS_SYNTHETIC_GARBAGE; i++) {
			Object[] array = new Object[4096];
			Arrays.setAll(array, value -> new Object());
			garbage.add(array);
		}
	}

	private void asyncs() {
		for (int i = 0; i < VETS_ASYNC_NB; i++) {
			Tracer tracer = GlobalTracer.get();
			Span asyncSpan = tracer.buildSpan("VetsAsync" + i).start();
			CompletableFuture.runAsync(() -> {
				try (Scope scope = tracer.activateSpan(asyncSpan)) {
					LockSupport.parkNanos(Duration.ofMillis(VETS_ASYNC_SLEEP_MS).toNanos());
				}
			}, executor).whenComplete((u, throwable) -> {
				asyncSpan.finish();
			});
		}
	}

	private void syntheticSleep() {
		LockSupport.parkNanos(Duration.ofMillis(VETS_SYNTHETIC_SLEEP_MS).toNanos());
	}

	int counter;

	public int syntheticCpu() {
		for (int period = 0; period < VETS_SYNTHETIC_CPU_PERIOD; period++) {
			counter = 0;
			for (int i = 0; i < Integer.MAX_VALUE / 8; i++) {
				counter++;
			}
		}
		return counter;
	}

	@GetMapping({ "/vets" })
	public @ResponseBody Vets showResourcesVetList() {
		// Here we are returning an object of type 'Vets' rather than a collection of Vet
		// objects so it is simpler for JSon/Object mapping
		Vets vets = new Vets();
		vets.getVetList().addAll(this.vets.findAll());
		return vets;
	}

	private void syntheticSpan() {
		Tracer tracer = GlobalTracer.get();
		Span synSpan = tracer.buildSpan("synthetic").withTag(Tags.SPAN_KIND, Tags.SPAN_KIND_CLIENT).start();
		try (Scope scope = tracer.activateSpan(synSpan)) {
			LockSupport.parkNanos(Duration.ofMillis(VETS_SYNTHETIC_SPAN_SLEEP_MS).toNanos());
		}
		finally {
			synSpan.finish();
		}
	}

}
