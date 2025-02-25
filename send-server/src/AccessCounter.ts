export class AccessCounter {
	state: DurableObjectState;

	constructor(state: DurableObjectState) {
		this.state = state;
	}

	async fetch(request: Request): Promise<Response> {
		const url = new URL(request.url);
		const cmd = url.searchParams.get('cmd');

		switch (cmd) {
			case 'get': {
				// Retrieve the current access count (default to 0).
				const count = (await this.state.storage.get<number>('accessCount')) || 0;
				return new Response(JSON.stringify({ count }), {
					headers: { 'Content-Type': 'application/json' },
				});
			}
			case 'increment': {
				// Get the current count, increment it, then store it back.
				let count = (await this.state.storage.get<number>('accessCount')) || 0;
				count++;
				await this.state.storage.put('accessCount', count);
				return new Response(JSON.stringify({ count }), {
					headers: { 'Content-Type': 'application/json' },
				});
			}
			default:
				return new Response('Unknown command', { status: 400 });
		}
	}
}
